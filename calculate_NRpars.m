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
%   metrics, to provide the user with an overall quality estimation. 
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
%   [parallelization]   = feature_function('parallelization')
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
%               and returns one of the following types:
%       'si'        1 frame, for spatial information (SI) features 
%       'ti'        Overlapping series 2 frames (overlapping by 1F) to
%                   calculate temporal information. If interlaced, de-interlace  
%                   and group pairs of fields of the same type.
%       'all'       The entire stimuli 
%
% 'parallelization' = ability for nrff to be run with parallel options
%
%       false      will not work with parallel options
%       true       will work with parallel options
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

    warning('off','MATLAB:MKDIR:DirectoryExists');
    
    
    % if given multiple datasets, process them one after another
    if length(nr_dataset) > 1
        for cnt=1:length(nr_dataset)
            NRpars(cnt) = calculate_NRpars(nr_dataset(cnt), base_dir, parallel_mode, feature_function);
        end
        return;
    end
    
    % Check whether this is an NR metric instead of an NR parameter.
    % (The difference is that NR parameters calculate values from media
    % files, while NR metrics combine the results from other NR parameters.)
    % If this is an NR metric, call its calculate function ('compose' mode) and return.
    tslice_mode = feature_function('read_mode');
    if strcmp(tslice_mode,'metric')
        % this is a metric instead of an NR parameter. Calculate as follows
        % and return
        NRpars = feature_function('compose', nr_dataset, base_dir);
        return;
    end


    % calculate directory paths, NRpars file name
    if base_dir(length(base_dir)) ~= '\'
        base_dir = fullfile(base_dir,'\');
    end
    subdir = fullfile(base_dir, join(['group_', feature_function('group')]),'\');
    parfile = fullfile(subdir,join(['NRpars_', feature_function('group'),'_', nr_dataset.dataset_name, '.mat']));
    
    if ~exist(subdir)
        mkdir(subdir);
    end


    if ~exist(parfile,'file')
        % File did not exist. Initialize a new structure for parameters and
        % save to parfile.
        NRpars = new_NRpars(nr_dataset, parfile, feature_function);
    else
        try
            % Load previously calculated NR parameters with this name
            load(parfile, 'NRpars');
    
            % and make sure contents and order match the input variables
            load_success = true;
            for cnt=1:length(nr_dataset.media)
                if ~strcmp(NRpars.media_name{cnt}, nr_dataset.media(cnt).name)
                    load_success = false;
                    break;
                end
            end

            % check if NRpars has the expected number of parameters
            if length(NRpars.par_name) ~= length(feature_function('parameter_names'))
                load_success = false;
            end

            % check if NRpars has the expected number of media
            if length(NRpars.media_name) ~= length([nr_dataset.media(:)])
                load_success = false;
            end

            % If previous parameters don't match expectations, erase the
            % NRpars file and recalculate. 
            if ~load_success
                warning('NRpars inconsistency detected. Discarding NRpars and re-calculating NRpars. Features retained');

                update_NRpars(base_dir, feature_function, 'update_pars');
                calculate_NRpars(nr_dataset, base_dir, parallel_mode, feature_function); 
                return;
            end
        catch
            % File existed but load failed. Initialize structure for
            % parameters and overwrite the old file.
            NRpars = new_NRpars(nr_dataset, parfile, feature_function);
        end
    end
    
    % Check for parallel mode compatibility
    try
        parallelization = feature_function('parallelization');
    catch
        % If the 'parallelization' option is missing from
        % @feature_function, it will throw an error. We will assume that
        % parallel processing is possible, because this is usually the
        % case. 
        parallelization = true;
    end
    if ~parallelization &&  ~strcmp(parallel_mode, 'none') 
        parallel_mode = 'none';
        fprintf("Feature Function does not support parallelization\nTurning off parallel processing\n");
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

    % turn off warnings that temporary variables will be cleared 
    warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary');

    % create list of NR features / NR parameters to be calculated
    temp = 1:length(nr_dataset.media);
    clip_list = temp(~NRpars.computed);

    if isempty(clip_list)
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
        feature_function('group'), nr_dataset.dataset_name, subdir);
    fprintf('%d of %d media files already calculated\n', ...
        length(nr_dataset.media) - length(clip_list), length(nr_dataset.media))
    fprintf(['\n' repmat('.',1,length(clip_list)) '\n\n']);

    if ~parallel_stimuli

        % disable parallel tslice mode if dataset is all images & 1 fps clips
        if isnan([nr_dataset.media(:).fps]) | max([nr_dataset.media(:).fps]) <= 1
            parallel_tslices = false;
        end
        
        for cnt = 1:length(clip_list)
            clip_num = clip_list(cnt);
            
            % calculate parameter for this clip
            [values, success] = calculate_one_media(nr_dataset, clip_num, base_dir, ...
                parallel_tslices, feature_function);
            if ~success
                % Delete parameter file, which may be the source of this error
                % This file will be fairly easy to reconstruct, so the cost
                % is low.
                delete(parfile);
                
                % throw the error again
                error('Aborting');  
            end
            
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
                tmp = [tmp sprintf('- Note: make sure your parameters are stored in a vector and not a cell array\n')];
        
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
            NRpars.version = 2;

            % Save NR parameters
            save (parfile, 'NRpars'); 
            fprintf('\b-\n');
        end

    else

        % move NRpars data into standalone variables, to enable parfor loop
        data = shiftdim(NRpars.data,1);
        computed = NRpars.computed;

        % disable parallel tslice mode if dataset is all images & 1 fps clips
        if isnan([nr_dataset.media(:).fps])
            parallel_tslices = false;
        elseif max([nr_dataset.media(:).fps]) <= 1
            parallel_tslices = false;
        end

        % Process in batches of 100, saving parameter results as we go
        for curr_start = 1:100:length(nr_dataset.media)
            curr_stop = min(curr_start + 99, length(nr_dataset.media));
            % Parallel loop to compute the features / parameters for all media       
            parfor cnt = curr_start:curr_stop
                try
                    if ~computed(cnt)
                        % calculate parameter for this clip
                        data(cnt,:) = ...
                            calculate_one_media(nr_dataset, cnt, base_dir, ...
                            parallel_tslices, feature_function);
                    end
                catch
                    % delete parameter file, which may be the source of this error
                    delete(parfile);
                    error('fatal error: run without parallel processing for more information');
                end
                fprintf('\b-\n');
            end

            % Move NRpars data back into NRpars structure
            % Note: there are only two dimensions to "data" so the shiftdim 
            % call shifts the dimensions to the right by one, wrapping.
            NRpars.data = shiftdim(data, 1);
            NRpars.computed(:) = true;
            NRpars.version = 2;

            % Save NR parameters
            save (parfile, 'NRpars'); 
        end

    end
    fprintf('\n');

end


% Initialize structure for parameters, NRpars
function [NRpars] = new_NRpars(nr_dataset, parfile, feature_function) 
    NRpars.par_name = feature_function('parameter_names');
    NRpars.media_name = cell(1,length(nr_dataset.media));
    NRpars.data = nan(length(NRpars.par_name), length(nr_dataset.media));
    NRpars.computed = false(1,length(nr_dataset.media));
    NRpars.dataset_name = nr_dataset.dataset_name;

    for cnt=1:length(nr_dataset.media)
        NRpars.media_name{cnt} = nr_dataset.media(cnt).name;
    end

    % Save NR parameter structure
    save (parfile, 'NRpars'); 
end