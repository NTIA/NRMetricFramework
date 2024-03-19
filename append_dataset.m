function [nr_dataset] = append_dataset(existing_dataset)
% IMPORT_NR_DATASET
%   Append an NR dataset with new files in the same directory as the orignal dataset
% SYNTAX
%   [nr_dataset] = append_dataset(existing_dataset)
%
% SEMANTICS
% Input variable 'existing_dataset' is either an Excel spreadsheet produced
% by 'import_dataset.m' or a dataset variable produced by 'import_dataset.m'
%
% When 'existing_dataset' is an Excel spreadsheet, load the described
% the dataset.  
%
% When 'existing_dataset' is a directory,create a new dataset based
% using the images and videos in that directory. Some values will be
% defaults, so it the dataset structure (returned) should be checked.
% See 'import_dataset.m'
%
% After the dataset is loaded (or created), look in the directory specified
% for this dataset. Append new media files to the dataset variable. 
%
% The return value ('nr_dataset') describes one subjective test, designed
% to train NR metrics.  
%
% See also 'import_dataset.m'

    
    %% ------------------------------------------------------------------------
    nr_dataset = import_dataset_append(existing_dataset);

    % check imported dataset
    check_dataset(nr_dataset);
    
end

function nr_dataset = import_dataset_append(nr_dataset)

   
    directory = nr_dataset.path;
    
    %iterate through all sub folders and files in the directory
    root_file_list = dir(directory); 
    file_list = [];
    for cnt=1:length(root_file_list)
        if root_file_list(cnt).isdir

            if isequal(root_file_list(cnt).name , '.') || isequal(root_file_list(cnt).name , '..')
                continue;
            end

            sub_folder_list = dir([directory root_file_list(cnt).name]);
                        
            for cnt2 = 1:length(sub_folder_list)
                           
                file_name = append(root_file_list(cnt).name, '\', sub_folder_list(cnt2).name);
                if isequal(sub_folder_list(cnt2).name , '.') || isequal(sub_folder_list(cnt2).name , '..') || sub_folder_list(cnt2).isdir
                    continue;
                end
                end_element = length(file_list) + 1;
                
                file_list(end_element).name = file_name;
                file_list(end_element).folder = sub_folder_list(cnt2).folder;
                file_list(end_element).date = sub_folder_list(cnt2).date;
                file_list(end_element).bytes = sub_folder_list(cnt2).bytes;
                file_list(end_element).isdir = sub_folder_list(cnt2).isdir;
                file_list(end_element).datenum = sub_folder_list(cnt2).datenum;

            end
        else
            %add logic to add the file to the file_list struct
            end_element = length(file_list) + 1;
            file_list(end_element).name = root_file_list(cnt).name;
            file_list(end_element).folder = root_file_list(cnt).folder;
            file_list(end_element).date = root_file_list(cnt).date;
            file_list(end_element).bytes = root_file_list(cnt).bytes;
            file_list(end_element).isdir = root_file_list(cnt).isdir;
            file_list(end_element).datenum = root_file_list(cnt).datenum;
        end
    end
    %RG_EDIT edits end here

    default_media = nr_dataset.media(1);
    
    fprintf('Appending dataset with media in %s\n', directory);
    if isnan(default_media.image_rows) || isnan(default_media.image_cols)
        default_media.image_rows = nan;
        default_media.image_cols = nan;
        fprintf('Media will be left at their original resolution, and not scaled to the display area\n\n');
    else
        fprintf('All media will be scaled to the display area of %d rows x %d columns\n\n', ...
            default_media.image_rows, default_media.image_cols);
    end

    %get how many files are in exisitng dataset and set as media_num
    media_num = length(nr_dataset.media);
    for cnt=1:length(file_list)
        %loop over exisiting dataset to check for exisitng entry, if not
        %unique, move to the next
        unique_file = 1;
        for i=1:length(nr_dataset.media)
            if strcmp(file_list(cnt).name, nr_dataset.media(i).file) == 1
                unique_file = 0;
                break;
            end
          
        end
        if unique_file == 0
            continue;
        end
        %existing, ignore
        % ignore directories in sub folders
        if file_list(cnt).isdir
            continue;
        end
        file_path = [nr_dataset.path file_list(cnt).name]; %RG_EDIT
        can_read = false;
        
        % initialize valid region
        top = nan;
        bottom = nan;
        left = nan;
        right = nan;
        
        
        % is this an image?
        try
            y = imread(file_path); 
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
            elseif strcmpi(file_list(cnt).name(len-3:len),'.png')
                nr_dataset.media(media_num).category3 = categorical({'png'}); 
                nr_dataset.media(media_num).codec = 'png';
            elseif strcmpi(file_list(cnt).name(len-3:len),'.bmp')
                nr_dataset.media(media_num).category3 = categorical({'bmp'}); 
                nr_dataset.media(media_num).codec = 'bmp';
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

            info = read_avi('info',file_path);
            y = read_avi('YCbCr',file_path, 'frames',1,1);
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
            % calculate Maximum Top, Left, Bottom, Right
            maxwindow_vec = zeros(4,1);
            for loop = 1:max(1, floor(nr_dataset.media(media_num).fps/2)):nr_dataset.media(media_num).stop
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
            v = VideoReader(file_path);
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

            is_valid = false; %RG_edit
            % Check for frame. Noted duration may be wrong. Also, function
            % "hasFrame" says "yes" when it should say "no" on the last
            % frame, when looping by +1 frame (read twice). 
            maxwindow_vec = ones(4,1);
            while hasFrame(v) && v.CurrentTime + 1/v.FrameRate < v.Duration
                is_valid = true; %RG_edit
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
            % This is because MATLAB occasionally loses the first and last
            % frame so ignore them.
            nr_dataset.media(media_num).start = ceil(start + 1/v.FrameRate);
            nr_dataset.media(media_num).stop = floor(stop - 1/v.FrameRate);
            nr_dataset.media(media_num).fps = v.FrameRate;

            % record valid region 
            nr_dataset.media(media_num).valid_top = maxwindow_vec(1);
            nr_dataset.media(media_num).valid_left = maxwindow_vec(2);
            nr_dataset.media(media_num).valid_bottom = maxwindow_vec(3);
            nr_dataset.media(media_num).valid_right = maxwindow_vec(4);

            % make sure can read the first and last image, using this
            % structure
            try
                start = nr_dataset.media(media_num).start;
                read_media ('frames', nr_dataset, media_num, start, start);

                stop = nr_dataset.media(media_num).stop;
                read_media ('frames', nr_dataset, media_num, stop, stop);
            catch
                warning('File %s cannot be read; discarding', file_list(cnt).name); %RG_edit
                continue;
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
    
    

    % note file name, best guess at clip name(File name blank in blank
    % datasets) 
    for media_num = 1:length(nr_dataset.media)
        fname = nr_dataset.media(media_num).file;
        if ~isempty(fname)
            locn = strfind(fname,'.');
            locn = locn(length(locn));
            if locn > length(nr_dataset.dataset_name) && contains(fname, nr_dataset.dataset_name)
                nr_dataset.media(media_num).name = strtrim(fname(1:locn-1));
            else
                nr_dataset.media(media_num).name = strtrim([nr_dataset.dataset_name '_' fname(1:locn-1)]);
            end
            
        end
        
    end
    
end
   