function [data] = ...
    export_NRpars(nr_dataset, base_dir, feature_function, fname, varargin)
% EXPORT_NRPARS
%   Write NR parameters or NR metrics and MOSs to a spreadsheet or matrix
% SYNTAX
% [data] = export_NRpars(nr_dataset, base_dir, feature_function, fname);
%   export_NRpars(...,'option');       % append options to above function call
%
% Note the following example, the square brackets [] for the dataset and
% the curly brackets {} for the NRFF functions:
%   export_NRpars([its4s_dataset bid_dataset livewild_dataset], base_dir, ...
%       {@nrff_blur @nrff_auto_enhancement}, 'c:\temp\temp.xls');
%
% SEMANTICS
%  The dataset structures and NR parameter structures are complex.
%  This function exports just the data needed to train or verify a parameter
%  or metric. Data returned in variables and saved to an XLS file. 
%
% Input Parameters:
%   nr_dataset          Data structure. Each describes an entire dataset 
%                       (name, file location, ...). Can be an array [] of
%                       several such datasets.
%   base_dir            Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature functions (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%                       Can be a list {} of several such datasets.
%   fname               The Excel filename used to save the data. 
%                       Set to [] to only return data as output parameters.
%                       Full path to file reccomended
%
%   Optional parameters. Some options contradict others.
%
%   'train',            Default. Return the training data only. 
%   'verify'            Return verification data. WARNING: this data
%                       must be held in reserve until final verification of
%                       a metric immediately prior to publication. The
%                       verification data must not be used for machine
%                       learning training/testing cycles. 
%
% Output Parameters:
%
%  data                 Table that holds everything written to the file "fname"
%   

    % parse optional input arguments
    do_train = true;    % default value is to export training data only
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
        else
            error('5th input variable not recognized')
        end
    end

    % change feature_function pointer into a cell array, if it isn't already
    if length(feature_function) == 1 && ~isa(feature_function,'cell')
        feature_function = { feature_function };
    end

    % check that this input argument is actually a function handle
    for cntF = 1:length(feature_function)
        if ~isa(feature_function{cntF},'function_handle')
            error('Feature_function{%d} must contain a pointer to a feature function', cntF);
        end
    end

    % find what want (training vs verification)
    if do_train
        want = categorical({'train'});
    else
        want = categorical({'verify'});
    end

    % initialize a table to hold the data. This is also our return variable
    data = table;

    % insert media names, MOS, RAW_MOS
    holdmedia = [];
    holdmos = [];
    holdraw_mos = [];
    for cntD = 1:length(nr_dataset)
        % find the media we want (training vs verification)
        train_bools = [[nr_dataset(cntD).media(:).category2] == want];
        
        % Copy this media names, mos, and raw_mos into the table.
        holdmedia = [holdmedia; {nr_dataset(cntD).media(train_bools).name}'];
        holdmos = [holdmos; [nr_dataset(cntD).media(train_bools).mos]'];
        holdraw_mos = [holdraw_mos; [nr_dataset(cntD).media(train_bools).raw_mos]'];
    end

    % Copy this media names, mos, and raw_mos into the table.
    data.media = holdmedia;
    data.mos = holdmos;
    data.raw_mos = holdraw_mos;

    % copy the features into the table, one at a time
    curr = 4;
    for cntF = 1:length(feature_function)
        % load in this feature, for all datasets
        for cntD = 1:length(nr_dataset)
            NRpars{cntD} = calculate_NRpars(nr_dataset(cntD), base_dir, 'none', feature_function{cntF});
        end
        
        % consider each parameter in this feature, one at a time
        for cntP = 1:length(NRpars{1}.par_name)
            % concatonate the parameter data
            holdpar = [];
            for cntD = 1:length(nr_dataset)
                % find the media we want (training vs verification)
                train_bools = [[nr_dataset(cntD).media(:).category2] == want];
                holdpar = [holdpar; NRpars{cntD}.data(cntP,train_bools)'];
                holdnan = isnan(NRpars{cntD}.data(cntP,train_bools)');
                if sum(holdnan) >=1
                    nan_ff = NRpars{cntD}.par_name(1,cntP);
                    msg = strcat("NaN present in ", nan_ff," ",nr_dataset(cntD).dataset_name);
                    warning(msg);
                end
                clear holdnan;
            end

            % copy into the table, fix the column name
            data.tmp = holdpar;
            data.Properties.VariableNames(curr) = {NRpars{cntD}.par_name{cntP}};
            curr = curr + 1;
        end
    end

    % Write this data to the XLS file, if requested.
    if ~isempty(fname)
        writetable(data,fname);
    end
end




