function [data] = nrff_auto_enhancement(mode, varargin)
% No-Reference Feature Function (NRFF)
%   Implement standard function calls to calculate image auto-enhancement features
%   That is, features associated with autocontrast, white level, and black
%   level. 
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'auto_enhancement';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names') 

    data{1} = 'white level';
    
    data{2} = 'r_block_std';
    data{3} = 'g_block_std';
    data{4} = 'b_block_std';

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names
elseif strcmp(mode, 'parameter_names')

    data{1} = 'white level'; % 98% white level, clipped at 150 maximum, ignore black border.
    
    data{2} = 'rgb_block_std';
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
elseif strcmp(mode, 'luma_only')
    data = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
elseif strcmp(mode, 'read_mode')
    data = 'si';

    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pixels')
    fps = varargin{1};
    y = varargin{2};
    cb = varargin{3};
    cr = varargin{4};

    % compute features.
    % Put all into the same data array, associated with the same feature name.
    
    
    % discard black border. Call Y <= 32 "black"
    col_max = max(y);
    row_max = max(y,[],2);
    
    % Warning: make sure this special case (all black image) returns the
    % same number of features as the rest of the function, or this function
    % will; fail.
    if max(col_max) <= 32
        % whole image is black; feature invalid
        data{1} = nan;
        data{2} = max(col_max);
    else
    
        min_col = 1;
        while col_max(min_col) <= 32
            min_col = min_col + 1;
        end
        max_col = length(col_max);
        while col_max(min_col) <= 32
            max_col = max_col - 1;
        end
        min_row = 1;
        while row_max(min_row) <= 32
            min_row = min_row + 1;
        end
        max_row = length(row_max);
        while row_max(min_row) <= 32
            max_row = max_row - 1;
        end

        y_nbe = y(min_row:max_row, min_col:max_col);

        % compute features.
        % Put all into the same data array, associated with the same feature name.
        [row,col] = size(y_nbe);
        pixels = row*col;
        y_vector = sort(reshape(y_nbe,row*col,1));


        offset_98 = floor(pixels*0.98); 
        data{1} = y_vector( offset_98 );
    end
    
    %
    [red, green, blue] = ycbcr2rgb_double(y, cb, cr, '128');
    [row,col] = size(red);
    rgb = nan(row,col,3);
    rgb(:,:,1) = red / 256;
    rgb(:,:,2) = green / 256;
    rgb(:,:,3) = blue / 256;
    rgb = rgb/128; % guess wants [0..1] scale

    % divide the image into approximately 100 blocks. Number of blocks will
    % be the same for each frame of a video. 
    [blocks] = divide_100_blocks(row, col, 0);

    for loop = 1:length(blocks)
        this_block = red(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);
        data{2}(loop) = st_statistic('std', this_block);
        
        this_block = green(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);
        data{3}(loop) = st_statistic('std', this_block);
        
        this_block = blue(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);
        data{4}(loop) = st_statistic('std', this_block);
    end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')


    % compute NR parameters, using mean over time
    % use nanmean, for safety

    feature_data = varargin{1,1};

    data(1) = nanmean(squeeze(feature_data{1}));
    if isnan(data(1))
        data(1) = 235;
    end

    % clip white level at 150 maximum
    data(1) = min(data(1), 150);

    data(2) = ( st_statistic('mean', feature_data{2}) + ...
            st_statistic('mean', feature_data{3}) + st_statistic('mean', feature_data{4}) );
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
