function [Mdata] = ...
    export_NRpars(nr_dataset, data_dir, feature_function, pname, varargin)
% EXPORT_NRPARS
%   Write NR parameter values, MOSs, and (optionally) interim features to
%   a spreadsheet for debugging, porting software to another language, or
%   manipulating NR parameters and NR features with other tools. 
%
% SYNTAX
% [Mdata] = export_NRpars(nr_dataset, data_dir, feature_function, path);
%   export_NRpars(...,'option');       % append options to above function call
%
% SEMANTICS
%  The dataset structures and NR parameter structures are complex.
%  This function exports just the data needed to train or verify a parameter
%  or metric. Data returned in variables and saved to an XLS file. 
%
% Input Parameters:
%   nr_dataset          Data structure. Must contain only one dataset.
%   data_dir            Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature function (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%                       Must contain only one function. 
%   pname               Path (directory) where the XLS file will be written. 
%                       Set to [] to only return per-media data as 
%                       output parameters. Full path to file recomended
%
%   Optional parameters. Some options contradict others.
%
%   'train'             Default. Return the training data only. 
%   'verify'            Return verification data. WARNING: this data
%                       must be held in reserve until final verification of
%                       a metric immediately prior to publication. The
%                       verification data must not be used for machine
%                       learning training/testing cycles.
%   'media', [m1, m2, ... mN] Export raw feature data for the numbered
%                       media. By default, export features for media 1 to 10. 
%   'nofeatures'        Do not write features; only write NR parameters.
%                       Use this option if no features are available, or if
%                       exporting metric_sawatch.m, or if features were deleted. 
%
% Output Parameters:
%
%  Mdata                Table that holds MOSs and NR parameters, as per
%                       file "data_group".
%
% Output Files:
%   Create one files in directory pname, named after the dataset and parameter
%   group (dataset_group.xls). This spreadsheet has the following sheets:
%
%   Sheet 'NRpars' contains columns for the media file names, MOS, RAW_MOS,  
%   and each NR parameter in feature_function.
% 
%   For each media selected, one sheet for each feature. Media and features
%   are numbered (e.g., M1, M2, ... and F1, F2, ...), and the sheets named
%   with these two abbreviations (e.g., M1_F1, M1_F2, M2_F1). Constraints
%   on XLS sheet names prevents more explanatory sheet names.
%
%   Each feature sheet contains one row for each frame in a video, or one
%   row for images. The columns contain feature values. If the feature
%   contains a vector of values, the column names append the vector offset, 
%   such as (1), (2), ...
%
% Example Function Calls:
%   
%   export_NRpars(ccriq_dataset, 'C:\features', @nrff_blur, 'c:\temp\', 'nofeatures')
%   export_NRpars(ccriq_dataset, 'C:\features', @metric_sawatch, 'c:\temp\', 'nofeatures')

    % parse optional input arguments
    do_train = true;    % default value is to export training data only
    do_features = true; % default is to write features
    Fmedia_num = 1:10; % by default, print features for media numbers 1 to 10.
    cnt = 1;
    varargin_len = nargin-4;
    while cnt <= varargin_len
        if strcmpi(varargin{cnt},'train')
            do_train = true;
            cnt = cnt + 1;
        elseif strcmpi(varargin{cnt},'verify')
            do_train = false;
            cnt = cnt + 1;
            
            warning('This data must be held in reserve until final verification of a metric immediately prior to publication. Verification data must not be used for machine learning training/testing cycles.');
        elseif strcmpi(varargin{cnt},'media')
            tmp = varargin{cnt+1};
            cnt = cnt + 2;

            if min(tmp) < 1 || max(tmp) > length([nr_dataset.media])
                error('Media numbers for input argument features must be between 1 and %d', length([nr_dataset.media]));
            else
                Fmedia_num = tmp;
            end
        elseif strcmpi(varargin{cnt},'nofeatures')
            do_features = false;
            cnt = cnt + 1;
        else
            error('optional input variable not recognized')
        end
    end

    % Figure out whether to save data to files. Make sure this is a path. 
    do_write = ~isempty(pname);
    if do_write
        [p1,p2,p3] = fileparts([pname '\']);
        if ~isempty(p2) || ~isempty(p3)
            warning('Saving data to ''%s''; ignoring file name', p1);
            pname = p1;
        end
    end

    % check that this input argument is actually a function handle. Ensure
    % input variable contains only one function.
    if length(feature_function) ~= 1
        error('Feature_function must contain eactly one NRFF')
    end
    if ~isa(feature_function,'function_handle')
        error('Feature_function must contain a pointer to a feature function');
    end

    % find what want (training vs verification)
    if do_train
        want = categorical({'train'});
    else
        want = categorical({'verify'});
    end

    % Make sure this is just one dataset.
    if length(nr_dataset) ~= 1
        error('input parameter nr_dataset must contain exactly one dataset');
    end

    % initialize a table to hold the data. This is also our return variable
    Mdata = table;

    % insert media names, MOS, and RAW_MOS
    holdmedia = [];
    holdmos = [];
    holdraw_mos = [];

    % find the media we want (training vs verification)
    train_bools = [[nr_dataset.media(:).category2] == want];
    
    % Copy this media names, mos, and raw_mos into the table.
    Mdata.media = [{nr_dataset.media(train_bools).name}'];
    Mdata.mos = [{nr_dataset.media(train_bools).mos}'];
    Mdata.raw_mos = [{nr_dataset.media(train_bools).raw_mos}'];
   
    % copy the features into the table, one at a time
    curr = 4;

    % load in this feature, for all datasets
    NRpars = calculate_NRpars(nr_dataset, data_dir, 'none', feature_function);
    
    % consider each parameter in this feature, one at a time
    for cntP = 1:length(NRpars.par_name)            
        % find the media we want (training vs verification)
        train_bools = [[nr_dataset.media(:).category2] == want];
        holdpar = [NRpars.data(cntP,train_bools)'];
        holdnan = isnan(NRpars.data(cntP,train_bools)');
        if sum(holdnan) >=1
            nan_ff = NRpars.par_name(1,cntP);
            msg = strcat("NaN present in ", nan_ff," ",nr_dataset.dataset_name);
            warning(msg);
        end
        clear holdnan;

        % copy into the table, fix the column name
        Mdata.tmp = holdpar;
        Mdata.Properties.VariableNames(curr) = {NRpars.par_name{cntP}};
        curr = curr + 1;
    end

    % Write this Mdata to the XLS file, if requested.
    feature_group = feature_function('group');
    if do_write
        fname = [pname '/' nr_dataset.dataset_name '_' feature_group '.xls'];
        writetable(Mdata,fname, 'Sheet','NRpars');
    else
        % if write not requested, stop and return the loaded data.
        return;
    end

    % if requested to not write features, stop here. 
    if ~do_features
        return;
    end


    %%
    % Next, organize the per=frame feature values from each NR metric into sheets.
    % Only do this if there is exactly one value per frame. 


    % Read NR features for this clip. Abort if not already computed.
    % otherwise, write these features to tabs of the Excel spreadsheet.


    feature_name = feature_function('feature_names');

    for Mcnt = Fmedia_num

        for Fcnt = 1:length(feature_name)
            % initialize a table to hold the feature data. 
            Fdata = table;

            % load this media's features into variable 'temp'
            name = sprintf('%s\\group_%s\\features\\%s\\%s.mat', ...
                data_dir, feature_group, feature_name{Fcnt}, nr_dataset.media(Mcnt).name);
            load( name, 'data' );

            % figure out how big this feature variable is.
            % d1 = frame offset
            % d2 and d3 offer 2 dimensions for data, but likely only
            % one of these is used.
            [d1,d2,d3] = size(data);
            
            % as long as the data is a vector, we can export
            if d2 > 1 && d3 > 1
                warning('Export of matrix per-frame features not implemented. Exiting early.')
                return;
            end

            % reshape into a 2-D variable (frame, feature-vector)
            % skip if this is a single number per frame
            if d2*d3 > 1
                data = reshape(data, [d1, d2*d3]);
            else
                % We want an array, not a table. MATLAB is converting
                % data into a table on read, which would cause problems
                % when we construct our table. 
                if istable(data)
                    data = table2array(data);
                end
            end

            % initialize table columns for the media name and frame
            % number.
            Fdata.media(1:d1) = {nr_dataset.media(Mcnt).name};                
            Fdata.frame = (1:d1)';
            curr = 3;

            % convert each feature offset in turn into a table column.
            for loop = 1:d2*d3
                Fdata.tmp = data(:,loop);
                Fdata.Properties.VariableNames{curr} = ...
                    sprintf('%s(%d)', feature_name{Fcnt}, loop);
                curr = curr + 1;
            end
            % write this information
            sheet = sprintf('M%d_F%d', Mcnt, Fcnt);
            writetable(Fdata,fname, 'Sheet',sheet);
        end


    end
end




