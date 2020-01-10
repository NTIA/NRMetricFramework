function [nr_dataset] = import_dataset(spreadsheet, dataset_name, display_rows, display_cols)
% IMPORT_NR_DATASET
%   Import an NR dataset from Excel spreadsheet, or create data structure for a new dataset
% SYNTAX
%   [nr_dataset] = import_dataset(spreadsheet)
%   [nr_dataset] = import_dataset(directory, dataset_name)
%   [nr_dataset] = import_dataset(directory, dataset_name, display_rows, display_cols)
% SEMANTICS
% When the first input variable is an Excel spreadsheet, load the described
% the dataset.  
%
% When the first input variable is a directory,create a new dataset based
% using the images and videos in that directory. Some values will be
% defaults, so it the dataset structure (returned) should be checked. 
%
% 'dataset_name' is the name of the new dataset. This should be a short
% string (e.g., 8 characters). Specify the name in single quotes, otherwise
% the program will note run (ie. 'test_ds')
%
% 'display_rows' and 'display_cols' specify the display area on the
% monitor. That is, the image or video was up-sampled or down-sampled to
% this region during the subjective test. Media processing will include
% this resizing. If not specified, the exact image size will be used, which
% is only valid if pixel-for-pixel display was used. 
%
% The return value ('nr_dataset') describes one subjective test, designed
% to train NR metrics.  
%
% See also 'export_dataset.m'

    %% ------------------------------------------------------------------------
    % check if this is a new dataset or an existing dataset in a
    % spreadsheet

    if ischar(spreadsheet)
        spreadsheet = char(spreadsheet);
    end
    
    % Test if argument is empty
    if isnumeric(spreadsheet) && isnan(spreadsheet)
        nr_dataset = make_empty_dataset(nan, nan, nan);

    % It's a directory, so we will create a new structure
    elseif isa(spreadsheet,'char') && exist(spreadsheet,'dir') == 7
        if ~exist('dataset_name','var') || ~ischar(dataset_name)
            error('When creating an NR dataset from a directory of media files, the dataset name must be specified');
        end
        if ~exist('display_rows','var') || ~exist('display_cols','var')  || ...
                ~isnumeric(display_rows) || ~isnumeric(display_cols) 
            display_rows = nan;
            display_cols = nan;
        end
        
        nr_dataset = make_empty_dataset(dataset_name, display_rows, display_cols);
        
        nr_dataset = import_dataset_new(spreadsheet, nr_dataset);
        
    % It's a file, so we assume a spreadsheet. read dataset
    elseif isa(spreadsheet,'char') && exist(spreadsheet, 'file') == 2
        % check fields
        if ~endsWith(spreadsheet,'.xls') && ~endsWith(spreadsheet,'.xlsx')
            error("Invalid Filename %s Extension, Must be .xls or .xlsx\n", string(filename))
        end
        if exist('display_rows','var') || exist('display_cols','var')
            error('When reading an NR dataset from Excel spreadsheet, the only input parameter is the filename');
        end
        
        nr_dataset = make_empty_dataset(nan, nan, nan);

        nr_dataset = import_dataset_spreadsheet(spreadsheet, nr_dataset);
    else
        error('Input variable must be either a directory of images and videos, or an excel spreadsheet');
    end
    
    
    % check imported dataset
    check_dataset(nr_dataset);
    
end

function nr_dataset = make_empty_dataset(dataset_name, display_rows, display_cols)
    %% ------------------------------------------------------------------------
    % default categories
    % category 1 splits between originals from camera or edting, vs compressed media
    category_list{1} = categorical({'original', 'compressed', 'error'});
    category_name{1} = 'Camera vs compression vs error';

    % category 2 is train vs verify
    category_list{2} = categorical({'train', 'verify'});
    category_name{2} = 'Training vs verification';

    % category 3 is camera list.
    category_list{3} = categorical({'av1','avc','hevc','mpeg2','mpeg4','video','jpeg','png'});
    category_name{3} = 'Codec';

    % cateogry 4 is monitor resolution; choose closest resolution 
    category_list{4} = categorical({...
        'qHD', ...  % 960 x 540
        'HD', ...   % 1280 x 720 
        'HD+', ...  % 1600 x 900 
        'FHD', ...  % 1920 x 1080 and 1900 x 1200
        'QHD', ...  % 2560 x 1440
        '4K', ...   % 3840 x 2160
        '5K', ...   % 5120 x 2880
        '8K'});     % 7680 x 4320 
    category_name{4} = 'Monitor resolution'; 

    % cateogries unique to this test 
    category_list{5} = categorical({});
    category_name{5} = ''; 
    category_list{6} = categorical({});
    category_name{6} = '';
    category_list{7} = categorical({});
    category_name{7} = '';
    category_list{8} = categorical({});
    category_name{8} = '';

    %% ------------------------------------------------------------------------
    % empty media
    media.name = '';
    media.file = '';
    media.bitstream_usable = false;
    media.image_rows = display_rows;
    media.image_cols = display_cols;
    media.video_standard = 'progressive';
    media.fps = nan;
    media.start = 1;
    media.stop = 1;
    media.valid_top = nan;
    media.valid_left = nan;
    media.valid_bottom = nan;
    media.valid_right = nan;
    media.mos = nan;
    media.sos = nan;
    media.raw_mos = nan;
    media.raw_sos = nan;
    media.jnd = nan;
    media.codec = '';
    media.profile = '';
    media.dynamic_range = 'sdr';
    media.color_space = '';
    media.tv_standard = '';
    media.display_ratio = [nan nan];
    media.category1 = categorical(missing);
    media.category2 = categorical({'train'});
    media.category3 = categorical(missing);
    media.category4 = categorical(missing);
    media.category5 = categorical(missing);
    media.category6 = categorical(missing);
    media.category7 = categorical(missing);
    media.category8 = categorical(missing);
    media.miscellaneous = {};


    %% ------------------------------------------------------------------------
    % establish basic structure. Fill out detail later.
    nr_dataset.test = dataset_name;
    nr_dataset.path = ' ';
    nr_dataset.media = media;
    nr_dataset.is_mos = true;
    nr_dataset.mos_range = [1 5];
    nr_dataset.raw_mos_range = [1 5];
    nr_dataset.category_list = category_list;
    nr_dataset.category_name = category_name;
    nr_dataset.miscellaneous = {};
    nr_dataset.sujson_file = '';
    nr_dataset.version = 1.0;

end

function nr_dataset = import_dataset_new(directory, nr_dataset)

    if directory(length(directory)) ~= '\'
        directory = [directory '\'];
    end
    nr_dataset.path = directory;
    file_list = dir(directory);
    
    default_media = nr_dataset.media(1);
    
    fprintf('Initializing new dataset from media in %s\n', directory);
    if isnan(default_media.image_rows) || isnan(default_media.image_cols)
        default_media.image_rows = nan;
        default_media.image_cols = nan;
        fprintf('Media will be left at their original resolution, and not scaled to the display area\n\n');
    else
        fprintf('All media will be scaled to the display area of %d rows x %d columns\n\n', ...
            default_media.image_rows, default_media.image_cols);
    end
    
    media_num = 1;
    for cnt=1:length(file_list)
        % ignore directories
        if file_list(cnt).isdir
            continue;
        end
        
        can_read = false;
        
        % initialize valid rgion
        top = nan;
        bottom = nan;
        left = nan;
        right = nan;
        
        
        % is this an image?
        try
            y = imread([directory '\' file_list(cnt).name]);
            can_read = true;
        catch
        end

        % yes. Fill in rest of image info
        if can_read
            nr_dataset.media(media_num) = default_media;
            nr_dataset.media(media_num).file = strtrim(file_list(cnt).name);
            nr_dataset.media(media_num).start = 1;
            nr_dataset.media(media_num).stop = 1;
            nr_dataset.media(media_num).fps = nan;
            
            % read image; assume whole image is valid
            y = read_media('all', nr_dataset, media_num);
            [bottom,right] = size(y);
            nr_dataset.media(media_num).valid_top = 1;
            nr_dataset.media(media_num).valid_left = 1;
            nr_dataset.media(media_num).valid_bottom = bottom;
            nr_dataset.media(media_num).valid_right = right;

            % note if JPEG compression
            len = length(file_list(cnt).name);
            
            if strcmpi(file_list(cnt).name(len-3:len),'.jpg') || strcmpi(file_list(cnt).name(len-4:len),'.jpeg')
                nr_dataset.media(media_num).category3 = categorical({'jpeg'}); 
                nr_dataset.media(media_num).codec = 'jpeg';
            end
            
            if strcmpi(file_list(cnt).name(len-3:len),'.png')
                nr_dataset.media(media_num).category3 = categorical({'png'}); 
                nr_dataset.media(media_num).codec = 'png';
            end
            
            % print results
            fprintf('media %d) image file %s valid region (%d,%d) (%d,%d)\n', ...
                media_num, nr_dataset.media(media_num).file, nr_dataset.media(media_num).valid_top, ...
                nr_dataset.media(media_num).valid_left, nr_dataset.media(media_num).valid_bottom, ...
                nr_dataset.media(media_num).valid_right);

            % go to next directory listing 
            media_num = media_num + 1;
            continue;
        end

        % is this an uncompressed AVI file?
        try
            locn = strfind(lower(file_list(cnt).name),'.avi');
            if isempty(locn)
                throw('not AVI');
            end
            locn = locn(length(locn));
            if locn + 3 ~= length(file_list(cnt).name)
                throw('not AVI');
            end

            info = read_avi('info',[directory '\' file_list(cnt).name]);
            y = read_avi('YCbCr',[directory '\' file_list(cnt).name], 'frames',1,1);
            can_read = true;
        catch
        end
        
        if can_read
            nr_dataset.media(media_num) = default_media;
           
            % record information from AVI file header
            nr_dataset.media(media_num).file = strtrim(file_list(cnt).name);
            nr_dataset.media(media_num).start = 1;
            nr_dataset.media(media_num).stop = info.NumFrames;
            nr_dataset.media(media_num).fps = info.FramesPerSecond;
            
            % read every a frame each 1/2 second, to compute valid region
            %Caculate Maximum Top, Left, Bottom, Right
            maxwindow_vec = zeros(4,1);
            for loop = 1:floor(nr_dataset.media(media_num).fps/2):nr_dataset.media(media_num).stop
                y = read_media ('frames', nr_dataset, media_num, loop, loop);
                [top, left, bottom, right] = valid_region_search_nosafety (y, top, left, bottom, right);
                comp_vec = [top, left, bottom, right];
                %Take the largest possible valid region
                for index = 1:4
                    if(maxwindow_vec(index) < comp_vec(index))
                        maxwindow_vec(index) = comp_vec(index);
                    end
                end
            end

            % record valid region 
            nr_dataset.media(media_num).valid_top = maxwindow_vec(1);
            nr_dataset.media(media_num).valid_left = maxwindow_vec(2);
            nr_dataset.media(media_num).valid_bottom = maxwindow_vec(3);
            nr_dataset.media(media_num).valid_right = maxwindow_vec(4);

            % print results
            fprintf('media %d) uncompressed AVI file %s valid region (%d,%d) (%d,%d)\n', ...
                media_num, nr_dataset.media(media_num).file, nr_dataset.media(media_num).valid_top, ...
                nr_dataset.media(media_num).valid_left, nr_dataset.media(media_num).valid_bottom, ...
                nr_dataset.media(media_num).valid_right);

            % go to next directory listing 
            media_num = media_num + 1;
            continue;
        end

        % is this a video that we'll read with MATLAB function VideoReader?
        try
            v = VideoReader([directory '\' file_list(cnt).name]);
            can_read = true;
        catch
        end
        
        if can_read
            warning("Currently using Matlab VideoReader to read media file. Several bugs are present and may result in inaccurate results")
            nr_dataset.media(media_num) = default_media;

            nr_dataset.media(media_num).file = strtrim(file_list(cnt).name);
            nr_dataset.media(media_num).start = ceil(v.CurrentTime * v.FrameRate);

            % Make sure the file contains a contiguous series of
            % frame numbers. This is a lot trickier than the previous two
            % cases, because the MATLAB read video utility currently has
            % bugs. Basically, the first frame, last frame, and some frames
            % inbetween may be missing. 6/21/2019. 
            prev_time = v.CurrentTime;
            start = round(v.CurrentTime * v.FrameRate);
            stop = start;

            is_valid = true;
            % Check for frame. Noted duration may be wrong. Also, function
            % "hasFrame" says "yes" when it should say "no" on the last
            % frame, when looping by +1 frame (read twice). 
            maxwindow_vec = ones(4,1);
            while hasFrame(v) && v.CurrentTime + 1/v.FrameRate < v.Duration
                rgb = readFrame(v);
                stop = stop + 1;
                
                % make sure CurrentTime indicates a constant frame rate, no
                % missing or skipped frames (ignroing 0.01 for rounding error)
                if v.CurrentTime - (prev_time + 1/v.FrameRate) > 0.01 
                    warning('Video file %s contains variable frame rate; convert to constant frame rate format; disarding', ...
                        file_list(cnt).name);
                    is_valid = false;
                    break;
                end
                prev_time = v.CurrentTime;
                
                % compute valid region
                [y] = rgb2ycbcr_double(single(rgb), '128', 'y_cb_cr');
                y  = image_scale(y, nr_dataset.media(media_num).image_rows, nr_dataset.media(media_num).image_cols, false);
                [top, left, bottom, right] =valid_region_search_nosafety (y, top, left, bottom, right);
                comp_vec = [top,left,bottom,right];
                %Take the largest possible valid region
                for index = 1:4
                    if(maxwindow_vec(index) < comp_vec(index))
                        maxwindow_vec(index) = comp_vec(index);
                    end
                end
            end
            if ~is_valid
                warning('File %s cannot be read; discarding', file_list(cnt).name);
                continue;
            end
            
            % record end condition
            % This should theoretically ignore the first and last frame
            % This is because matlab occasionally loses the first and last
            % frame so ignore them.
            nr_dataset.media(media_num).start = start + 1/v.FrameRate;
            nr_dataset.media(media_num).stop = stop - 1/v.FrameRate;
            nr_dataset.media(media_num).fps = v.FrameRate;

            % record valid region 
            nr_dataset.media(media_num).valid_top = maxwindow_vec(1);
            nr_dataset.media(media_num).valid_left = maxwindow_vec(2);
            nr_dataset.media(media_num).valid_bottom = maxwindow_vec(3);
            nr_dataset.media(media_num).valid_right = maxwindow_vec(4);

            % make sure can read the first and last image, using this
            % structure
            try
                read_media ('frames', nr_dataset, media_num, start, start);
                read_media ('frames', nr_dataset, media_num, stop, stop);
            catch
                error('file %s duration mismatch, critical file read error', [directory '\' file_list(cnt).name]);
            end

            
            % print results
            fprintf('media %d) video file %s frames [%d..%d] valid region (%d,%d) (%d,%d)\n', ...
                media_num, nr_dataset.media(media_num).file, ...
                start, stop, nr_dataset.media(media_num).valid_top, ...
                nr_dataset.media(media_num).valid_left, nr_dataset.media(media_num).valid_bottom, ...
                nr_dataset.media(media_num).valid_right);

            % go to next directory listing 
            media_num = media_num + 1;
            continue;
        end
        
        if ~can_read
            fprintf('--- File %s cannot be read; discarding\n', file_list(cnt).name);
            continue;
        end
        
    end
    
    %Perform Training and Validation Split
    if(length(nr_dataset.media) > 100)
        %Split Data Set into 90 10 split for training and verification
        [is_train, ~, ~] = training_validation_split(nr_dataset.media, 0.9);
        [nr_dataset.media(is_train).category2] = deal(categorical({'train'}));
        [nr_dataset.media(~is_train).category2] = deal(categorical({'verify'}));
    end
    
    

    % note file name, best guess at clip name(File name blank in blank datasets)
    for media_num = 1:length(nr_dataset.media)
        fname = nr_dataset.media(media_num).file;
        if ~isempty(fname)
            locn = strfind(fname,'.');
            locn = locn(length(locn));
            if locn > length(nr_dataset.test) && strcmpi(fname(1:length(nr_dataset.test)), nr_dataset.test)
                nr_dataset.media(media_num).name = strtrim(fname(1:locn-1));
            else
                nr_dataset.media(media_num).name = strtrim([nr_dataset.test '_' fname(1:locn-1)]);
            end
            
        end
        
    end
    
end
    


function nr_dataset = import_dataset_spreadsheet(spreadsheet, nr_dataset)
    %%
    % otherwise, initialize each media, based on number of rows in
    % spreadsheet. This will give default values (e.g., for category1)
    % This establishes the structure. Now read data and fill the structure. 
    
    media = nr_dataset.media(1);
    
    [num,~,~] = xlsread(spreadsheet,'Format');
    [rows,~] = size(num);
    for cnt=2:rows
        nr_dataset.media(cnt) = media;
    end
    
    %% ------------------------------------------------------------------------
    % read Dataset
    
    [~,~,raw] = xlsread(spreadsheet,'Dataset');
    if ~strcmp(raw{1,1},'test') || ~strcmp(raw{2,1},'path') || ~strcmp(raw{3,1},'is_mos') || ...
            ~strcmp(raw{4,1},'mos range') || ~strcmp(raw{5,1},'raw_mos range') || ...
            ~strcmp(raw{6,1},'miscellaneous') || ~strcmp(raw{7,1},'sujson_file') || ~strcmp(raw{8,1},'version')
        error('Spreadsheet format incorrect, page "Dataset". ');
    end

    nr_dataset.test = raw{1,2};
    nr_dataset.path = raw{2,2};
    if nr_dataset.path(length(nr_dataset.path)) ~= '\'
        nr_dataset.path = [nr_dataset.path '\'];
    end

    if ~islogical(raw{3,2})
        error('Spreadsheet format incorrect. Dataset sheet, B3, must be a logical (true or false)');
    end
    nr_dataset.is_mos = raw{3,2};
    nr_dataset.mos_range(1) = raw{4,2};
    nr_dataset.mos_range(2) = raw{4,3};
    nr_dataset.raw_mos_range(1) = raw{5,2};
    nr_dataset.raw_mos_range(2) = raw{5,3};
    [~,cols]= size(raw);
    for cnt=1:cols-1
        if ~isnan(raw{6,1+cnt}) & ~isempty(raw{6,1+cnt})
            nr_dataset.miscellaneous{cnt} = raw{6,1+cnt};
        end
    end
    if isempty(raw{7,2}) || isnan(raw{7,2})
        nr_dataset.sujson_file = '';
    else
        nr_dataset.sujson_file = raw{7,2};
    end
    nr_dataset.version = raw{8,2};


    %% ------------------------------------------------------------------------
    % read Format
    
    [~,~,raw] = xlsread(spreadsheet,'Format');
    if ~strcmp(raw{1,1},'file') || ~strcmp(raw{1,2},'name') || ...
            ~strcmp(raw{1,3},'codec') || ~strcmp(raw{1,4},'profile') || ...
            ~strcmp(raw{1,5},'dynamic_range') || ~strcmp(raw{1,6},'color_space') || ...
            ~strcmp(raw{1,7},'tv_standard') || ~strcmp(raw{1,8},'display_ratio_horiz') || ...
            ~strcmp(raw{1,9},'display_ratio_vert') || ~strcmp(raw{1,10},'miscellaneous') 

        error('Spreadsheet header row incorrect, page "Format". Match values produced by export_dataset.m.');
    end

    [rows,~] = size(raw);

    % copy data for each stimuli
    for cnt=1:rows-1
        nr_dataset.media(cnt).file = strtrim(raw{1+cnt,1});
        nr_dataset.media(cnt).name = strtrim(raw{1+cnt,2});
        if ~isnan(raw{1+cnt,3})
            nr_dataset.media(cnt).codec = raw{1+cnt,3};
        end
        if ~isnan(raw{1+cnt,4})
            nr_dataset.media(cnt).profile = raw{1+cnt,4};
        end
        if ~isnan(raw{1+cnt,5})
            nr_dataset.media(cnt).dynamic_range = raw{1+cnt,5};
        end
        if ~isnan(raw{1+cnt,6})
            nr_dataset.media(cnt).color_space = raw{1+cnt,6};
        end
        if ~isnan(raw{1+cnt,7})
            nr_dataset.media(cnt).tv_standard = raw{1+cnt,7};
        end
        if ~isnan(raw{1+cnt,8}) && ~isnan(raw{1+cnt,9})
            nr_dataset.media(cnt).display_ratio = [raw{1+cnt,8} raw{1+cnt,9}];
        end
        
        [~,cols]= size(raw);
        for loop=10:cols
            if ~isnan(raw{1+cnt,loop}) 
                nr_dataset.media(cnt).miscellaneous{cnt-9} = raw{1+cnt,loop};
            end
        end
        
    end

    
    %% ------------------------------------------------------------------------
    % read "Read" page
    
    [num,~,raw] = xlsread(spreadsheet,'Read');
    if ~strcmp(raw{1,1},'file') || ~strcmp(raw{1,2},'name') || ...
            ~strcmp(raw{1,3},'bitstream_usable') || ~strcmp(raw{1,4},'image_rows') || ...
            ~strcmp(raw{1,5},'image_cols') || ~strcmp(raw{1,6},'video_standard') || ...
            ~strcmp(raw{1,7},'fps') || ~strcmp(raw{1,8},'start') || ...
            ~strcmp(raw{1,9},'stop') || ~strcmp(raw{1,10},'valid_top') || ...
            ~strcmp(raw{1,11},'valid_left') || ~strcmp(raw{1,12},'valid_bottom') || ...
            ~strcmp(raw{1,13},'valid_right') 

        error('Spreadsheet header row incorrect, page "Read". Match values produced by export_dataset.m.');
    end

    [rows,~] = size(num);

    % copy data for each stimuli
    for cnt=1:rows
        if ~strcmp(nr_dataset.media(cnt).file,raw{1+cnt,1})
            error(sprintf("Media files different on ""Format"" and ""Read"" pages on row %d with ""%s"" and ""%s""", cnt, nr_dataset.media(cnt).file, raw{1+cnt,1}));
        end
        if ~strcmp(nr_dataset.media(cnt).name,raw{1+cnt,2})
            error(sprintf("Media names different on ""Format"" and ""Read"" pages on row %d with ""%s"" and ""%s""", cnt, nr_dataset.media(cnt).file, raw{1+cnt,1}));
        end
        nr_dataset.media(cnt).bitstream_usable = raw{1+cnt,3};
        nr_dataset.media(cnt).image_rows = raw{1+cnt,4};
        nr_dataset.media(cnt).image_cols = raw{1+cnt,5};
        nr_dataset.media(cnt).video_standard = (raw{1+cnt,6});
        nr_dataset.media(cnt).fps = raw{1+cnt,7};
        nr_dataset.media(cnt).start = raw{1+cnt,8};
        nr_dataset.media(cnt).stop = raw{1+cnt,9};
        nr_dataset.media(cnt).valid_top = raw{1+cnt,10};
        nr_dataset.media(cnt).valid_left = raw{1+cnt,11};
        nr_dataset.media(cnt).valid_bottom = raw{1+cnt,12};
        nr_dataset.media(cnt).valid_right = raw{1+cnt,13};
    end
    
    
    %% ------------------------------------------------------------------------
    % read MOS
    
    [num,~,raw] = xlsread(spreadsheet,'MOS');
    if ~strcmp(raw{1,1},'file') || ~strcmp(raw{1,2},'name') || ...
            ~strcmp(raw{1,3},'mos') || ...
            ~strcmp(raw{1,4},'sos') || ~strcmp(raw{1,5},'raw_mos') || ...
            ~strcmp(raw{1,6},'raw_sos') || ~strcmp(raw{1,7},'jnd') 

        error('Spreadsheet header row incorrect. Match values produced by export_dataset.m.');
    end

    [rows,~] = size(num);

    % copy data for each stimuli
    for cnt=1:rows
        if ~strcmp(nr_dataset.media(cnt).file,raw{1+cnt,1})
            error('Media files different on "Format" and "MOS" pages');
        end
        if ~strcmp(nr_dataset.media(cnt).name,raw{1+cnt,2})
            error('Media names different on "Format" and "MOS" pages');
        end
        nr_dataset.media(cnt).mos = raw{1+cnt,3};
        nr_dataset.media(cnt).sos = raw{1+cnt,4};
        nr_dataset.media(cnt).raw_mos = raw{1+cnt,5};
        nr_dataset.media(cnt).raw_sos = raw{1+cnt,6};
        nr_dataset.media(cnt).jnd = raw{1+cnt,7};
    end
    
    
    %% ------------------------------------------------------------------------
    % read category data
    [~,~,raw] = xlsread(spreadsheet,'Category_list');
    [rows,~] = size(raw);
    for loop = 1:8
        list = categorical({});
        % copy data
        for cnt=1:rows-1
            if ~isnan(raw{1+cnt,loop})
                if isnumeric(raw{1+cnt,loop})
                    list(1,cnt) = categorical(raw{1+cnt,loop});
                else
                    list(1,cnt) = categorical(raw(1+cnt,loop));
                end
            end
        end
        nr_dataset.category_list{loop} = list;
    end

    %% ------------------------------------------------------------------------
    % read category data
    [~,~,raw] = xlsread(spreadsheet,'Category_name');
    [rows,cols] = size(raw);
    if rows < 8 || cols < 2
        error('Some data missing from "Category_name" sheet; unexpected size of data.');
    end
    for cnt=1:8
        if isnan(raw{cnt,2})
            raw{cnt,2} = '';
        end
        nr_dataset.category_name{1,cnt} = raw{cnt,2};
    end


    %% ------------------------------------------------------------------------
    % read category list
    [~,~,raw] = xlsread(spreadsheet,'Category');
    [rows,cols] = size(raw);
    if rows < length(nr_dataset.media) + 1 || cols < 10
        error('Some data missing from "Cateogry" sheet; unexpected size of data.');
    end
    
    for cnt=1:length(nr_dataset.media)
        % copy data
        if ~isnan(raw{1+cnt,3})
            if isnumeric(raw{1+cnt,3})
                nr_dataset.media(cnt).category1 = categorical(raw{1+cnt,3});
            else
                nr_dataset.media(cnt).category1 = categorical(raw(1+cnt,3));
            end
        end
        if ~isnan(raw{1+cnt,4})
            if isnumeric(raw{1+cnt,4})
                nr_dataset.media(cnt).category2 = categorical(raw{1+cnt,4});
            else
                nr_dataset.media(cnt).category2 = categorical(raw(1+cnt,4));
            end
        end
        if ~isnan(raw{1+cnt,5})
            if isnumeric(raw{1+cnt,5})
                nr_dataset.media(cnt).category3 = categorical(raw{1+cnt,5});
            else
                nr_dataset.media(cnt).category3 = categorical(raw(1+cnt,5));
            end
        end
        if ~isnan(raw{1+cnt,6})
            if isnumeric(raw{1+cnt,6})
                nr_dataset.media(cnt).category4 = categorical(raw{1+cnt,6});
            else
                nr_dataset.media(cnt).category4 = categorical(raw(1+cnt,6));
            end
        end
        if ~isnan(raw{1+cnt,7})
            if isnumeric(raw{1+cnt,7})
                nr_dataset.media(cnt).category5 = categorical(raw{1+cnt,7});
            else
                nr_dataset.media(cnt).category5 = categorical(raw(1+cnt,7));
            end
        end
        if ~isnan(raw{1+cnt,8})
            if isnumeric(raw{1+cnt,8})
                nr_dataset.media(cnt).category6 = categorical(raw{1+cnt,8});
            else
                nr_dataset.media(cnt).category6 = categorical(raw(1+cnt,8));
            end
        end
        if ~isnan(raw{1+cnt,9})
            if isnumeric(raw{1+cnt,9})
                nr_dataset.media(cnt).category7 = categorical(raw{1+cnt,9});
            else
                nr_dataset.media(cnt).category7 = categorical(raw(1+cnt,9));
            end
        end
        if ~isnan(raw{1+cnt,10})
            if isnumeric(raw{1+cnt,10})
                nr_dataset.media(cnt).category8 = categorical(raw{1+cnt,10});
            else
                nr_dataset.media(cnt).category8 = categorical(raw(1+cnt,10));
            end
        end
        % error checking
        if ~strcmp(nr_dataset.media(cnt).name,raw{1+cnt,2}) || ...
                ~strcmp(nr_dataset.media(cnt).file,raw{1+cnt,1})
            error(sprintf("Spreadsheet rows on Category page differ from rows on Format page on row %d with ""%s""/""%s"" and ""%s""/""%s""", cnt, nr_dataset.media(cnt).name, nr_dataset.media(cnt).file, raw{1+cnt,2}, raw{1+cnt,1}));
        end
    end
end

