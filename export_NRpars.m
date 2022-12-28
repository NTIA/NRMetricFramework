function [values, mos, par_name, media_name] = ...
    export_NRpars(nr_dataset, base_dir, feature_function, fname, varargin)
% EXPORT_NRPARS
%   Write NR parameters or NR metrics and MOSs to a spreadsheet or matrix
% SYNTAX
% [values, mos, par_name, media_name] ...
%   = export_NRpars(nr_dataset, base_dir, feature_function, fname);
%   export_NRpars(...,'option');       % append options to above function call
% SEMANTICS
%  The dataset structures and NR parameter structures are complex.
%  This function exports just the data needed to train or verify a parameter
%  or metric. Data returned in variables and saved to an XLS file. 
%
% Input Parameters:
%   nr_dataset          Data structure. Each describes an entire dataset (name, file location, ...)
%   base_dir            Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature functions (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%   fname               The Excel filename used to save the data. 
%                       Set to [] to only return data as output parameters. 
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
%  values           The feature matrix (par_name, file_list)
%  mos              The MOS vector (file_list)
%  par_name         Names of parameters
%  media_name       Names of media files (images or videos0
%   
%--------------------------------------------------------------------------

    % parse optional input arguments
    do_train = true;    % default value
    cnt = 1;
    varargin_len = nargin-4;
    while cnt <= varargin_len
        if strcmpi(varargin{cnt},'train')
            do_train = true;
            cnt = cnt + 1;
        elseif strcmpi(varargin{cnt},'verify')
            do_train = false;
            cnt = cnt + 1;
            
            warning('This data must be held in reserve until final verification of a metric immediately prior to publication.\nVerification data must not be used for machine learning training/testing cycles.');
        else
            error('5th input variable not recognized')
        end
    end

    % check that this input argument is actually a function handle
    if ~isa(feature_function,'function_handle')
        error('third input variable (feature_function) must contain a pointer to a feature function');
    end
       
    % load (or calculate then load) the parameter values
    NRpars = calculate_NRpars(nr_dataset, base_dir, 'none', feature_function);

    % find the media we want (training vs verification)
    if do_train
        want = categorical({'train'});
    else
        want = categorical({'verify'});
    end
    train_bools = [[nr_dataset.media(:).category2] == want];
    
    % Copy data into return variables
    values = NRpars.data(:,train_bools);
    par_name = NRpars.par_name;
    media_name = NRpars.media_name(:,train_bools);
    mos = [nr_dataset.media(train_bools).mos];
    
    % Write this data to the XLS file, if requested.
    if ~isempty(fname)
        if do_train
            sheet = sprintf('%s_Train', NRpars.dataset_name);
        else
            sheet = sprintf('%s_Verify', NRpars.dataset_name);
        end
        
        xlswrite(fname, {'Media'}, sheet,'A1');
        xlswrite(fname, media_name', sheet, sprintf('A2:A%d',length(mos)+1));

        xlswrite(fname, {'MOS'}, sheet, 'B1');
        xlswrite(fname, mos', sheet, sprintf('B2:B%d',length(mos)+1));

        xlswrite(fname, par_name, sheet, sprintf('C1:%c1','B'+length(par_name)));
        xlswrite(fname, values', sheet, 'C2');
    end
end




