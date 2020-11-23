function [par_data, success] = calculate_one_media(nr_dataset, media_num, ...
    base_dir, parallel_tslices, feature_function)
% Run an NRFF on one media (image or video) 
% SYNTAX
%    par_data = calculate_one_media(nr_dataset, media_num, ...
%       base_dir, parallel_tslices, feature_function)
% SEMANTICS
%  Run an NRFF on one media (image or video). This is an internal function, 
%  used by calculate_NRpars. It can also be called directly, to debug a
%  feature_function using a particular image or media.
%
% Input Variables
%   nr_dataset = Data struction. Each describes an entire dataset (name, file location, ...)
%   media_num   Number of the media to be examined, an offset in
%               nr_dataset.media
%   base_dir =  Path to directory where NR features and NR parameters are stored.
%
%   parallel_tslices = true or false, indicating whether or not parallel
%               processing is requested
%
%   feature_function = Function call to compute the feature. 
%       This no-reference feature function (NRFF) must adhere to the
%       interface specified in calculate_NRpars.
%
% Output Variables
%   par_data    Data returned by the feature_function, mode 'pars'
%   success     true or false, indicating whether operation finished correctly 

    success = true;
    
    % locate subdirectory for this NRFF  
    if base_dir(length(base_dir)) ~= '\' && base_dir(length(base_dir)) ~= '/'
        base_dir = [base_dir '\'];
    end
    subdir = [base_dir 'group_' feature_function('group') '\'];


    % constant. Number of frames to read at a time in parallel mode. This
    % number can be changed. 
    read_time = 10; 
    

    tslice_mode = feature_function('read_mode');
    if ~ischar(tslice_mode) || (~strcmp(tslice_mode,'all') && ~strcmp(tslice_mode,'si') && ~strcmp(tslice_mode,'ti'))
                
        tmp = sprintf('Error within ''feature_function'' input argument of ''calculate_NRpars'':\n');
        tmp = [tmp sprintf('- calculating ''%s'' features\n', feature_function('group'))];
        tmp = [tmp sprintf('- feature_function for ''%s'' called with ''read_mode''\n', feature_function('group'))];
        tmp = [tmp sprintf('- returned value not recognized; ''all'', ''si'', or ''ti'' expected\n\n')];

        tmp = [tmp sprintf('Function ''calculate_NRpars'' was calculating features for the following media:\n') ];
        tmp = [tmp sprintf('- dataset %s, media number %d\n', nr_dataset.test, media_num)];
        tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
        tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];

        success = false;
        
        error(tmp);
    end

    % retrieve names of these NR features
    feature_name = feature_function('feature_names');
    
    %%
    % try to read NR features for this clip. May be already computed.
    % if so, calculate the NR parameters and return.
    try
        % load NR features
        for cnt = 1:length(feature_name)
            feature_data{cnt} = load_data(subdir, feature_name{cnt}, nr_dataset, media_num);
        end
        
        % compute the NR parameters from the NR features
        [par_data] = feature_function('pars', feature_data, nr_dataset.media(media_num).fps, ...
            [nr_dataset.media(media_num).image_rows, nr_dataset.media(media_num).image_cols]);
        
        return;
    catch    
        % load of NR features failed
        % must compute features and parameters
        clear feature_data;
        clear fdata;
    end
    
    %%
    
    % Read media and call function to calculate features
    if strcmp(tslice_mode,'all')
        % read all frames at once.
        if feature_function('luma_only')
            [y] = read_media('all', nr_dataset, media_num);
        else
            [y,cb,cr] = read_media('all', nr_dataset, media_num);
        end

        % if tslice_mode is 'all', no parallel processing. Calculate with a
        % single function call. 
        if feature_function('luma_only')
            feature_data = feature_function('pixels', nr_dataset.media(media_num).fps, y); 
        else
            feature_data = feature_function('pixels', nr_dataset.media(media_num).fps, y, cb, cr);
        end
        
    elseif strcmp(tslice_mode, 'si') || strcmp(tslice_mode, 'ti')
        % read 1 frame at a time, or temporal information (two frames at once)

        % figure out overlap, if any, for TI mode
        if strcmp(nr_dataset.media(media_num).video_standard,'progressive')
            is_progressive = true;
        else
            is_progressive = false;
        end
        if strcmp(tslice_mode, 'si')
            is_overlap = 0;
            overlap = 0;
        else
            is_overlap = 1;
            if is_progressive
                overlap = 1;
            else
                overlap = 2;
            end
        end

        if ~parallel_tslices
            % linear processing.
            
            % read all frames at once.
            if feature_function('luma_only')
                [y] = read_media('all', nr_dataset, media_num);
            else
                [y,cb,cr] = read_media('all', nr_dataset, media_num);
            end
            
            % compute number of frames available
            [~,~,total] = size(y);
            
            % if this is an image and we are calculating 'ti', duplicate the frame 
            if total == 1 && strcmp(tslice_mode, 'ti')
                if is_progressive
                    y(:,:,2) = y;
                    if ~feature_function('luma_only')
                        cb(:,:,2) = cb;
                        cr(:,:,2) = cr;
                    end
                    total = 2;
                else
                    tmp = sprintf('Error detected in a dataset''s structure\n');
                    tmp = [tmp sprintf('- Media marked as an interlaced image; this is impossible\n\n')];
                    
                    tmp = [tmp sprintf('Function ''calculate_NRpars'' was calculating features for the following media:\n') ];
                    tmp = [tmp sprintf('- dataset %s media number %d\n', nr_dataset.test, media_num)];
                    tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
                    tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];

                    success = false;
        
                    error(tmp);
                end
            end
                
            for cnt = 1:total-overlap
                % calculate NR features
                if is_overlap
                    if feature_function('luma_only')
                        this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,[cnt cnt+overlap]));
                    else
                        this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,[cnt cnt+overlap]), cb(:,:,[cnt cnt+overlap]), cr(:,:,[cnt cnt+overlap]));
                    end
                else
                    if feature_function('luma_only')
                        this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,cnt:cnt));
                    else
                        this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,cnt:cnt), cb(:,:,cnt:cnt), cr(:,:,cnt));
                    end
                end

                % error checking
                if ~iscell(this_frame)
                    tmp = sprintf('Error within ''feature_function'' input argument of ''calculate_NRpars'':\n');
                    tmp = [tmp sprintf('- calculating ''%s'' features\n', feature_function('group'))];
                    tmp = [tmp sprintf('- mode ''pixels'' must return a cell array, with one cell for each feature name\n')];
                    
                    success = false;
        
                    error(tmp)
                end
                if length(this_frame) ~= length(feature_function('feature_names'))
                    tmp = sprintf('Error within ''feature_function'' for group ''%s'', which is an input argument of ''calculate_NRpars'':\n', feature_function('group'));
                    tmp = [tmp sprintf('- ''pixel'' mode returns %d features, but ''feature_names'' mode specifies %d features\n\n', ...
                        length(this_frame), length(feature_function('feature_names')))];

                    tmp = [tmp sprintf('Function ''calculate_NRpars'' was calculating features for the following media:\n') ];
                    tmp = [tmp sprintf('- dataset %s media number %d\n', nr_dataset.test, media_num)];
                    tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
                    tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];

                    success = false;
        
                    error(tmp);
                end

                if cnt == 1
                    for pcnt = 1:length(this_frame)
                        feature_data{pcnt}(1,:,:) = this_frame{pcnt};
                    end
                else
                    for pcnt = 1:length(this_frame)
                        [~,s1A,s2A] = size(feature_data{pcnt});
                        [s1B,s2B,s3B] = size(this_frame{pcnt});
                        if s1A ~= s1B || s2A ~= s2B
                            tmp = sprintf('Error within ''feature_function'' for group ''%s'', which is an input argument of ''calculate_NRpars'':\n', feature_function('group'));
                            tmp = [tmp sprintf('- feature %d changes in size from one frame to the next. Check frame %d.\n\n', pcnt, cnt)];

                            tmp = [tmp sprintf('Function ''calculate_NRpars'' was calculating features for the following media:\n') ];
                            tmp = [tmp sprintf('- dataset %s media number %d\n', nr_dataset.test, media_num)];
                            tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
                            tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];

                            success = false;
        
                            error(tmp);
                        elseif s3B > 1
                            tmp = sprintf('Error within ''feature_function'' for group ''%s'', which is an input argument of ''calculate_NRpars'':\n', feature_function('group'));
                            tmp = [tmp sprintf('- feature %d contains three (3) or more dimensions; it must have no more than two dimensions\n\n', pcnt)];

                            tmp = [tmp sprintf('Function ''calculate_NRpars'' was calculating features for the following media:\n') ];
                            tmp = [tmp sprintf('- dataset %s media number %d\n', nr_dataset.test, media_num)];
                            tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
                            tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];

                            success = false;
        
                            error(tmp);
                        end
                        feature_data{pcnt}(cnt,:,:) = this_frame{pcnt};
                    end
                end
            end
            
        else
            % Parallel mode. Read video in chunks of frames. Make arrays with
            % start & stop times for read
            start = nr_dataset.media(media_num).start:read_time:(nr_dataset.media(media_num).stop-is_overlap);
            stop = start + read_time - 1 + is_overlap;
            total = length(start);
            stop(total) = nr_dataset.media(media_num).stop;

            % compute NR features.
            parfor cnt = 1:total
                try
                    if feature_function('luma_only')
                        [y] = read_media('frames', nr_dataset, media_num, start(cnt), stop(cnt));
                    else
                        [y,cb,cr] = read_media('frames', nr_dataset, media_num, start(cnt), stop(cnt));
                    end
                catch
                    tmp = sprintf('Error reported by ''read_media'' function:\n\n%s\n\n', lasterr);
                    tmp = [tmp sprintf('Error occured when ''calculate_NRpars'' tried to read:\n') ];
                    tmp = [tmp sprintf('- dataset %s media number %d\n', nr_dataset.test, media_num)];
                    tmp = [tmp sprintf('- frames %d to %d\n', start(cnt), stop(cnt))];
                    tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
                    tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];
                    tmp = [tmp sprintf('- compute ''%s'' features\n', feature_function('group'))];
                    tmp = [tmp sprintf('- write features and parameters to %s\n', subdir)];
                    
                    success = false;
        
                    error(tmp);
                end
                
                [~,~,frames_per_read] = size(y);
                
                for loop = 1:frames_per_read-overlap
                
                    % calculate NR features. Depending on mode, pass in one
                    % image or pair of images; luma-only or full color.
                    if is_overlap
                        if feature_function('luma_only')
                            this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,[loop loop+overlap]));
                        else
                            this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,[loop loop+overlap]), cb(:,:,[loop loop+overlap]), cr(:,:,[loop loop+overlap]));
                        end
                    else
                        if feature_function('luma_only')
                            this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,loop));
                        else
                            this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,loop), cb(:,:,loop), cr(:,:,loop));
                        end
                    end

                    % error checking
                    if ~iscell(this_frame)
                        tmp = sprintf('Error within ''feature_function'' input argument of ''calculate_NRpars'':\n');
                        tmp = [tmp sprintf('- calculating ''%s'' features\n', feature_function('group'))];
                        tmp = [tmp sprintf('- mode ''pixels'' must return a cell array, with one cell for each feature name\n')];

                        success = false;
        
                        error(tmp)
                    end
                    if length(this_frame) ~= length(feature_function('feature_names'))
                        tmp = sprintf('Error within ''feature_function'' for group ''%s'', which is an input argument of ''calculate_NRpars'':\n', feature_function('group'));
                        tmp = [tmp sprintf('- ''pixel'' mode returns %d features, but ''feature_names'' mode specifies %d features\n\n', ...
                            length(this_frame), length(feature_function('feature_names')))];
                        tmp = [tmp '- run without parallel processing (''none'' mode) for more information\n'];

                        success = false;
        
                        error(tmp);
                    end

                    % copy data for later integration
                    fdata(cnt).loop{loop} = this_frame;
                end
            end
            
            try
                % reconstruct par_data.
                % get tslices in the correct order
                offset = 1;
                for cnt=1:total
                    for loop=1:length(fdata(cnt).loop)
                        curr = fdata(cnt).loop{loop};
                        for pcnt = 1:length(feature_function('feature_names'))
                            feature_data{pcnt}(offset,:,:) = curr{pcnt};
                        end
                        offset = offset + 1;
                    end
                end
            catch
                success = false;
        
                error('Inconsistent number of features per frame for some features. Run without parallel processing for more information.');
            end
        end
        
    else
        
        tmp = sprintf('parallel_mode parsing failure. Function ''calculate_NRpars'' trying to run a non-existant mode\n');

        success = false;
        
        error(tmp);
    end

    %% 
    
    % compute the NR parameters from the NR features
    [par_data] = feature_function('pars', feature_data, nr_dataset.media(media_num).fps, ...
            [nr_dataset.media(media_num).image_rows, nr_dataset.media(media_num).image_cols]);

    % error check number of parameters
    if length(feature_function('parameter_names')) ~= length(par_data)
        tmp = sprintf('Error within ''feature_function'' for group ''%s'', which is an input argument of ''calculate_NRpars'':\n', feature_function('group'));
        tmp = [tmp sprintf('- %d parameter names specified\n', length(feature_function('parameter_names')))];
        tmp = [tmp sprintf('- %d parameters returned by ''pars'' mode\n\n', length(par_data))];
        
        tmp = [tmp sprintf('Function ''calculate_NRpars'' was calculating features for the following media:\n') ];
        tmp = [tmp sprintf('- dataset %s media number %d\n', nr_dataset.test, media_num)];
        tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
        tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];
        
        success = false;
        
        error(tmp);
    end

    % save NR features
    for cnt = 1:length(feature_name)
        save_data(feature_data{cnt}, subdir, feature_name{cnt}, nr_dataset.media(media_num).name);
    end


    
end



%% -----------------------------------------------------------------------
function data = load_data(subdir, feature, nr_dataset, media_num)
% load features previously computed

    name = sprintf('%sfeatures\\%s\\%s.mat', ...
        subdir, feature, nr_dataset.media(media_num).name);
    if ~exist(name,'file')
        tmp = sprintf('Error in ''calculate_NRpars'':\n');
        tmp = [tmp sprintf('- reading feature %s\n', feature)];
        tmp = [tmp sprintf('- dataset %s\n', nr_dataset.test)];
        tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
        tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];
        tmp = [tmp sprintf('- parameter status file says this feature has been calculated\n')];
        tmp = [tmp sprintf('- but features cannot be read from %s\n\n', name)];

        error(tmp);
    end
    load( name, 'data' );   
    
end

%% ----------------------------------------------------------------------
function save_data(data, is_path, feature_name, media_name)
% SAVE_DATA
%  Write out features to a file with a standard name.
% SYNTAX
%  [name_exists name] = save_data(data, is_path, feature_name, media_name);
% DESCRIPTION
%  Write out a feature stream ('data') to file into a sub-directory
%  'feature_name', with the is_path & drive specified by 'is_path'.  
%  'media_name' is the name of this media, from a dataset structure.
%  The feature stream ('data') should encompass all or part of the features
%  for one media in nr_dataset.  Feature variables will have the name 'data', 
%  to simplify the task of later routines automatically reading many such files. 
%

    % Remove end slashes from feature_name and is_path
    if strcmp(feature_name(length(feature_name)),'/') || strcmp(feature_name(length(feature_name)),'\')
        feature_name = feature_name(1:(length(feature_name)-1));
    end
    if strcmp(is_path(length(is_path)),'/') || strcmp(is_path(length(is_path)),'\')
        is_path = is_path(1:(length(is_path)-1));
    end

    % Generate feature file name
    name_mat = [ is_path '\features\' feature_name '\' media_name '.mat'];

    name_exists = exist(name_mat, 'file');

    % Create directory if needed
    if ~exist(is_path,'dir')
        mkdir(is_path);
    end
    if ~exist([is_path '\features\'],'dir')
        mkdir([is_path '\features\']);
    end
    if ~exist([is_path '\features\' feature_name],'dir')
        mkdir([is_path '\features\'], feature_name);
    end

    % Write feature file
    save (name_mat, 'data');

end



