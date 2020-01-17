function [NRpars] = calculate_NRpars(nr_dataset, base_dir, parallel_mode, feature_function) 
% CALCULATE_NRPARS
%   Support tool to calculate a NR feature on all videos or images in a dataset.
% SYNTAX
%   [NRpars] = calculate_NRpars(nr_dataset, ...
%       base_dir, parallel_mode, feature_function); 
% SEMANTICS
%   This function provides all support tools needed to calculate 
%   no-reference (NR) features and NR parameters. 
%   - NR feature provides multiple values for each image or video. 
%   - NR parameter provides one value for the entire video or image. 
%   Other functions will combine NR features and/or NR parameters into NR
%   metrics, to provide the user with an overall quality estimatino. 
%
% Input Parameters:
%   nr_dataset = Data struction. Each describes an entire dataset (name, file location, ...)
%   base_dir = Path to directory where NR features and NR parameters are stored.
%
%   parallel_model = 
%       'none'      Linear calculation. Parallel processing toolbox avoided.
%       'stimuli'   Parallel processing on the stimuli level. 
%       'tslice'    Divide each stimuli into segments for parallel processing  
%                   Note: tslice mode automatically disabled for images 
%                   (presented as 1 fps sequences), due to inefficiencies. 
%       'all'       Do parallel processing on both the stimuli and tslice level. 
%
%                   (Note: 'all' and 'stimuli' mode cannot save progress
%                   calculating NRpars. Only features can be saved against computer crash.)
%
%   feature_function = Function call to compute the feature. 
%       This no-reference feature function (NRFF) must adhere to the
%       interface specified below.
%
% -------------------------------------------------------------------------
% FEATURE_FUNCTION
%   Input parameter 'feature_function' must have the following interface
%       [data] = feature_function(mode, varargin);
%           'mode' is a char array specifying the action to be performed
%           'data' is a cell array with 1 or more return values.
%   Each feature function must implement the following calls:
%
% STANDARD SYNTAX
%   [feature_group]     = feature_function('group')
%   [feature_names]     = feature_function('feature_names')
%   [parameter_names]   = feature_function('parameter_names')
%   [bool]              = feature_function('luma_only')
%   [read_mode]         = feature_function('read_mode')
%   [feature_data]      = feature_function('pixels', fps, y)
%   [feature1_data]     = feature_function('pixels', fps, y, cb, cr)
%   [par_data]          = feature_function('pars', feature_data, fps, image_size);
%
% STANDARD SEMANTICS
% 'feature_group' mode returns the feature names
%   Output
%       feature_group = char array (short) uniquely identifying this group
%           of features and parameters. 
%
% 'feature_names' mode returns the feature names
%   Output
%       feature_names = cell array with feature names
%
% 'parameter_names' mode returns the parameter names
%   Output
%       parameter_names = cell array with parameter names
%
% 'luma_only' mode returns color space option
%   Output
%       bool = true for luminance only;  
%       bool = false if 'pixels' mode tales y, cb, and cr.
%
% 'read_mode' = Type of time-slice (tslice) that 'pixels' call takes as input
%               and returns one of the folowing types:
%       'si'        1 frame, for spatial information (SI) features 
%       'ti'        Overlapping series 2 frames (overlapping by 1F) to
%                   calculate temporal information. If interlaced, de-interlace  
%                   and group pairs of fields of the same type.
%       'all'       The entire stimuli 
%
% 'pixels' mode calculates these features on one tslice
%   Input:
%       fps = frames per second; NaN for images
%       y = image or 1 frame of video, luma only, as a 2D array; 
%           more generally, a tslice of video. Vertical & horizontal size 
%           may be smaller than the viewing monitor
%       cb, cr = Cb and Cr planes associated with luma plane y
%   Output:
%       feature_data = Cell array, one cell for each feature name.
%           Each cell must contain either a single value, vector, or
%           2-dimensional matrix. These return variables must be returned
%           in same order as the feature names. 
%
% 'pars' mode
%   Input:
%       fps = frames per second; NaN for images
%       image_size = [rows,cols] = Size of image as displayed on the
%                   monitor during subjective testing, including black
%                   border.
%       feature_data = Cell array, one cell for each feature name
%           Each cell contain data associated with one feature, all frames. 
%           Size is (t), (t, x) or (t, x, y) where  t is tslice number 
%           (frame number, for 1F features). Otherwise as returned by
%           'pixels' function call. 
%   Output:
%       [par_data] = array, containing the value for each NR parameter
%
% -------------------------------------------------------------------------
% FEATURE_FUNCTION for NR Metrics
%   The following variant feature_function is used to combine already 
%   calculated data from several other feature_functions into a single NR
%   metric.
% STANDARD SYNTAX
%   [feature_group]     = feature_function('group')
%   [parameter_names]   = feature_function('parameter_names')
%   [read_mode]         = feature_function('read_mode')
%   [par_data]          = feature_function('compose', nr_dataset, base_dir);
% SEMANTICS
%   Where NRFF takes as input images or videos and outputs NR features and  
%   NR parameters, this NR metric takes as input NR parameters and outputs
%   NR metrics. 
%
% 'feature_group' mode returns the feature names
%   Output
%       feature_group = char array (short) uniquely identifying this group
%           of features and parameters. 
%
% 'parameter_names' mode returns the parameter names
%   Output
%       parameter_names = cell array with parameter names
%
% 'read_mode' = 'metric'
%`      Function calculate_NRpars.m uses this value ('metric') to select
%       the alternate execution path.
%
% 'compose' mode  calculates the NR metric.
%   Output:
%       [par_data] = array, containing the value for each NR parameter or
%                    NR metric

    % if given multiple datasets, process them one after another
    if length(nr_dataset) > 1
        for cnt=1:length(nr_dataset)
            NRpars(cnt) = calculate_NRpars(nr_dataset(cnt), base_dir, parallel_mode, feature_function);
        end
        return;
    end
    
    % Check whether this is an NR metric instead of an NR parameter.
    % If so, call its calculate function ('compose' mode) and return.
    tslice_mode = feature_function('read_mode');
    if strcmp(tslice_mode,'metric')
        % this is a metric instead of an NR parameter. Calculate as follows
        % and return
        NRpars = feature_function('compose', nr_dataset, base_dir);
        return;
    end


    % calculate directory paths, NRpars file name
    if base_dir(length(base_dir)) ~= '\'
        base_dir = [base_dir '\'];
    end
    subdir = [base_dir 'group_' feature_function('group') '\'];
    parfile = [subdir 'NRpars_' feature_function('group') '_' nr_dataset.test '.mat'];
    
    if ~exist(subdir)
        mkdir(subdir);
    end


    try
        % Either load previously calculated NR parameters with this name, if any
        load(parfile, 'NRpars');

        % and make sure contents and order match the input variables
        for cnt=1:length(nr_dataset.media)
            if ~strcmp(NRpars.media_name{cnt}, nr_dataset.media(cnt).name)
                fprintf('List of clips differs. Discarding and re-calculate NR parameters. Features retained\n\n');
                error('recalculate NRpars');

                % * * * add more robust error handling * * * 
            end
        end
    catch
        % or initialize structure for parameters, NRpars
        NRpars.par_name = feature_function('parameter_names');
        NRpars.media_name = cell(1,length(nr_dataset.media));
        NRpars.data = nan(length(NRpars.par_name), length(nr_dataset.media));
        NRpars.computed = false(1,length(nr_dataset.media));
        NRpars.test = nr_dataset.test;

        for cnt=1:length(nr_dataset.media)
            NRpars.media_name{cnt} = nr_dataset.media(cnt).name;
        end

        % Save NR parameter structure
        save (parfile, 'NRpars'); 
    end

    % interpret parallel mode as two variables
    if strcmpi(parallel_mode,'none')
        parallel_stimuli = false;
        parallel_tslices = false;
    elseif strcmpi(parallel_mode,'stimuli')
        parallel_stimuli = true;
        parallel_tslices = false;
    elseif strcmpi(parallel_mode,'tslice')
        parallel_stimuli = false;
        parallel_tslices = true;
    elseif strcmpi(parallel_mode,'all')
        parallel_stimuli = true;
        parallel_tslices = true;
    else
        tmp = sprintf('Error ''calculate_NRpars'':\n');
        tmp = [tmp sprintf('- parallel processing mode %s not recognized\n', parallel_mode)];
        tmp = [tmp sprintf('- expected ''all'', ''stimuli'', ''tslice'', or ''none''')];

        error(tmp);
    end


    % Preconditions:
    %   - variable "NRpars" must have the same order and clip structure as nr_dataset. 
    %   - NRpars.computed(clip_num) must be 
    %           true if NR parameters were calculated and saved in NRpars.data
    %           false otherwise 


    % create list of NR features / NR parameters to be calculated
    temp = 1:length(nr_dataset.media);
    clip_list = temp(~NRpars.computed);

    if isempty(clip_list)
        fprintf('%s already calculated for %s\n\n', feature_function('group'), nr_dataset.test);
        return;
    end
    
    if parallel_stimuli == false || parallel_tslices == false
        poolobj = [];
    else
        % start default parallel pool, if needed and doesn't exist
        poolobj = gcp('nocreate'); % If no pool, do not create new one.
        if isempty(poolobj) && (parallel_stimuli || parallel_tslices)
            parpool;
        end
    end

    % keep track of progress
    fprintf('Progress %s NR features, dataset %s, directory %s:\n', ...
        feature_function('group'), nr_dataset.test, subdir);
    fprintf(['\n' repmat('.',1,max(size(nr_dataset.media))) '\n\n']);

    if ~parallel_stimuli

        % disable parallel tslice mode if dataset is all images & 1 fps clips
        if isnan([nr_dataset.media(:).fps]) | max([nr_dataset.media(:).fps]) <= 1
            parallel_tslices = false;
        end
        
        for cnt = 1:length(clip_list)
            clip_num = clip_list(cnt);
            
            % calculate parameter for this clip
            values = compute_one_clip(nr_dataset, clip_num, subdir, ...
                parallel_tslices, feature_function, parfile);
            if iscell(values)
                tmp = sprintf('Error within ''feature_function'' input argument of ''calculate_NRpars'':\n');
                tmp = [tmp sprintf('- calculating ''%s'' features\n', feature_function('group'))];
                tmp = [tmp sprintf('- mode ''pars'' returned a cell array; it must return numeric values\n')];
        
                % delete parameter file, which may also contain this error
                delete(parfile);

                error(tmp);
            elseif ~isnumeric(values)
                tmp = sprintf('Error within ''feature_function'' input argument of ''calculate_NRpars'':\n');
                tmp = [tmp sprintf('- calculating ''%s'' features\n', feature_function('group'))];
                tmp = [tmp sprintf('- mode ''pars'' must return numeric values\n')];
        
                % delete parameter file, which may also contain this error
                delete(parfile);

                error(tmp);
            elseif length(values) ~= length(feature_function('parameter_names'))
                tmp = sprintf('Error within ''feature_function'' input argument of ''calculate_NRpars'':\n');
                tmp = [tmp sprintf('- calculating ''%s'' features\n', feature_function('group'))];
                tmp = [tmp sprintf('- mode ''pars'' returned %d values, but mode ''pixels'' returns %d parameter names\n', ...
                    length(values), length(feature_function('parameter_names')))];
        
                % delete parameter file, which may also contain this error
                delete(parfile);

                error(tmp);
            elseif numel(values) ~= length(feature_function('parameter_names'))
                tmp = sprintf('Error within ''feature_function'' input argument of ''calculate_NRpars'':\n');
                tmp = [tmp sprintf('- calculating ''%s'' features\n', feature_function('group'))];
                tmp = [tmp sprintf('- mode ''pars'' must return a vector of numbers: one value for each parameter\n')];
        
                % delete parameter file, which may also contain this error
                delete(parfile);

                error(tmp);
            end
            NRpars.data(:,clip_num) = values;
            NRpars.computed(clip_num) = true;

            % Save NR parameters
            save (parfile, 'NRpars'); 
            fprintf('\b-\n');
        end

    else

        % move NRpars data into standalone variables, to enable parfor
        data = shiftdim(NRpars.data(:,clip_list),1);
        computed = NRpars.computed(clip_list);
        curr_clips = nr_dataset.media(clip_list);

        % disable parallel tslice mode if dataset is all images & 1 fps clips
        if isnan([nr_dataset.media(:).fps])
            parallel_tslices = false;
        elseif max([curr_clips(:).fps]) <= 1
            parallel_tslices = false;
        end


        parfor cnt = 1:length(clip_list)

            % calculate parameter for this clip
            data(cnt,:) = ...
                compute_one_clip(nr_dataset, cnt, subdir, ...
                parallel_tslices, feature_function, parfile);
            computed(cnt) = true;
            fprintf('\b-\n');
        end

        % move NRpars data back into NRpars structure
        data = shiftdim(data,1);

        for cnt=1:length(clip_list)
            NRpars.data(:,clip_list(cnt)) = data(:,cnt);
            NRpars.computed(clip_list(cnt)) = computed(cnt);
        end

        % Save NR parameters
        save (parfile, 'NRpars'); 

    end
    fprintf('\n');


end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function par_data = compute_one_clip(nr_dataset, media_num, ...
    base_dir, parallel_tslices, feature_function, parfile)
%
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
            feature_data{cnt} = load_data(base_dir, feature_name{cnt}, nr_dataset, media_num);
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

                    error(tmp);
                end
            end
                
            for cnt = 1:total-overlap
                % caclulate NR features
                if feature_function('luma_only')
                    this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,cnt:cnt+overlap));
                else
                    this_frame = feature_function('pixels', nr_dataset.media(media_num).fps, y(:,:,cnt:cnt+overlap), cb(:,:,cnt:cnt+overlap), cr(:,:,cnt:cnt+overlap));
                end

                % error checking
                if ~iscell(this_frame)
                    tmp = sprintf('Error within ''feature_function'' input argument of ''calculate_NRpars'':\n');
                    tmp = [tmp sprintf('- calculating ''%s'' features\n', feature_function('group'))];
                    tmp = [tmp sprintf('- mode ''pixels'' must return a cell array, with one cell for each feature name\n')];
                    
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

                            error(tmp);
                        elseif s3B > 1
                            tmp = sprintf('Error within ''feature_function'' for group ''%s'', which is an input argument of ''calculate_NRpars'':\n', feature_function('group'));
                            tmp = [tmp sprintf('- feature %d contains three (3) or more dimensions; it must have no more than two dimensions\n\n', pcnt)];

                            tmp = [tmp sprintf('Function ''calculate_NRpars'' was calculating features for the following media:\n') ];
                            tmp = [tmp sprintf('- dataset %s media number %d\n', nr_dataset.test, media_num)];
                            tmp = [tmp sprintf('- media file %s\n', nr_dataset.media(media_num).file)];
                            tmp = [tmp sprintf('- directory %s\n', nr_dataset.path)];

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
                    tmp = [tmp sprintf('- write features and parameters to %s\n', base_dir)];
                    
                    error(tmp);
                end
                
                [~,~,frames_per_read] = size(y);
                
                for loop = 1:frames_per_read-overlap
                
                    % caclulate NR features. Depending on mode, pass in one
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

                        error(tmp)
                    end
                    if length(this_frame) ~= length(feature_function('feature_names'))
                        tmp = sprintf('Error within ''feature_function'' for group ''%s'', which is an input argument of ''calculate_NRpars'':\n', feature_function('group'));
                        tmp = [tmp sprintf('- ''pixel'' mode returns %d features, but ''feature_names'' mode specifies %d features\n\n', ...
                            length(this_frame), length(feature_function('feature_names')))];
                        tmp = [tmp '- run without parallel processing (''none'' mode) for more information\n'];

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
                        for pcnt = 1:length(feature_function('feature_names'))
                            feature_data{pcnt}(offset,:,:) = fdata(cnt).loop{loop};
                        end
                        offset = offset + 1;
                    end
                end
            catch
                error('Inconsistent number of features per frame for some features. Run without parallel processing for more information.');
            end
        end
        
    else
        
        tmp = sprintf('parallel_mode parsing failure. Function ''calculate_NRpars'' trying to run a non-existant mode\n');

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
        
        % delete parameter file, which also contains this error
        delete(parfile);

        error(tmp);
    end

    % save NR features
    for cnt = 1:length(feature_name)
        save_data(feature_data{cnt}, base_dir, feature_name{cnt}, nr_dataset.media(media_num).name);
    end


    
end



%% -----------------------------------------------------------------------
function data = load_data(base_dir, feature, nr_dataset, media_num)
% load features previously computed

    name = sprintf('%sfeatures\\%s\\%s.mat', ...
        base_dir, feature, nr_dataset.media(media_num).name);
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
%  The feature stream ('data') should encompas all or part of the features
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



