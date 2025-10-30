function [data] = nrff_zip(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard function calls to calculate features that estimate
%  the average compression level of a video. 
% 
%  Note, this algorithm(LZW) is one of the oldest(1984 or before),
%  simplest, and fastest compression algorithms where can be changed
%  to single character huffman coding.  If want to use huffman encoding, 
%  then any byte/data order will no longer matter.
% 
%  Also, this algorithm only looks left to right and not in all directions
%  Like most landmark or similar pixel test functions(FAST/BRISK/other).
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'zip';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')
    data{1} = 'compressed_size';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names
elseif strcmp(mode, 'parameter_names')
    data{1} = 'compression_ratio';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
elseif strcmp(mode, 'luma_only')
    data = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
elseif strcmp(mode, 'read_mode')
    data = 'si';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tell calculate_NRpars to use parallel_mode
elseif strcmp(mode, 'parallelization')
    data = true; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pixels')
    fps = varargin{1};
    y = varargin{2};
    cb = varargin{3};
    cr = varargin{4};
    [rows,cols,frames] = size(y);

    if frames ~= 1
        error('This feature must be given exactly 1 frame in the tslice function call');
    end

    % Truncate color size(value of "1" means flooring to nearest integer) and max key length
    color_truncate_size = 1;
    color_seg_max_length = 8;

    % Convert color values to 1D list
    leng = rows * cols;

    for row = 2:rows:2
        y (row,:) = flip( y(row,:));
        cb(row,:) = flip(cb(row,:));
        cr(row,:) = flip(cr(row,:));
    end

    list = reshape( ...
               [ ...
                    dec2hex(floor( y' / color_truncate_size), 2) ...
                    dec2hex(floor(cb' / color_truncate_size), 2) ...
                    dec2hex(floor(cr' / color_truncate_size), 2) ...
               ]', [], 1)';

    % Get word dictionary where word can be several characters.  Also, individual 
    %   luma/colors and lists of color is stored as potentially long hex strings:
    %   https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch
    %   https://courses.cs.washington.edu/courses/csep521/09au/DictionaryCoding.pdf
    word_counts = containers.Map();
    index       =                1;

    while index<=leng
        % Get longest string that doesn't match
        long_val_length = 5;
        while index + long_val_length <= leng && long_val_length < color_seg_max_length * 6 && isKey(word_counts, list(index:index + long_val_length))
            long_val_length = long_val_length + 6;
        end

        % Set new longest string to hash
        end_index = min(index + long_val_length, leng);
        if long_val_length < color_seg_max_length * 6
            word_counts(list(index:end_index)) = 0;
        end
        index = index + long_val_length + 1;
    end

    % Count word frequencies
    index = 1;

    while index<=leng
        % Get longest string that doesn't match
        long_val_length = 5;
        while index + long_val_length <= leng && long_val_length < color_seg_max_length * 6 && isKey(word_counts, list(index:index + long_val_length))
            long_val_length = long_val_length + 6;
        end

        % Usually, move back character as went 1 character passed an existing hashed string
        if long_val_length>1 && isKey(word_counts, list(index:index + long_val_length - 6)) && ~isKey(word_counts, list(index:index + long_val_length))
            long_val_length = long_val_length - 6;
        end

        % Increment word count where occasionally a new unhashed word may
        %     appear as longer words are being matched than the first
        %     search.
        if isKey(word_counts, list(index:index + long_val_length))
            word_counts(list(index:index + long_val_length)) = word_counts(list(index:index + long_val_length)) + 1;
        else
            word_counts(list(index:index + long_val_length)) = 1;
        end

        index = index + long_val_length + 1;
    end

    % Normalize frequencies and get compressed size
    word_lengths     =    containers.Map();
    words            =   keys(word_counts);
    counts           = values(word_counts);
    word_count_total =    sum([counts{:}]);
    compressed_size  =                   0;

    for index = 1:length(word_counts)
        word  = char(words(index));
        count = word_counts(word);
        if count > 0
            % Get estimated upper word lengths for colors.
            %     Note, below is worst case which should always allow for
            %     an available(unused) compressed character sequence(s).
            %     This method is simpler and doesn't use tree weighting.
            % Note, a 3 byte color here could be say 1 byte or 10 bytes
            %     where a multiple of 3 bytes is not required.
            word_length = ceil((log(word_count_total) - log(count)) / log(256));
            word_lengths(word) = word_length;

            % Get compressed size
            compressed_size = compressed_size + count * word_length;
        end
    end

    % Set return variables
    data{1} = compressed_size;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')

    % Get needed image parameters
    % 
    feature_data = varargin{1,1};
    fps = varargin{2};
    image_size  = varargin{3};

    compressed_size = feature_data{1};

    % Get image dimensions
    rows = image_size(1);
    cols = image_size(2);

    % fprintf("(compressed_size: %d)(ratio: %f)\n", compressed_size, compressed_size / (rows * cols))

    data(1) = mean(compressed_size) / (rows * cols);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
