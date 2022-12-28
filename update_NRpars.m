function update_NRpars(base_dir, feature_function, action)
%   This convenience function updates or erases parameter files. 
% SYNTAX
%    update_NRpars(base_dir, feature_function, action)
% SEMANTICS
%   This convenience function helps the user update or erase parameter
%   files. 
%
% Input Parameters:
%   base_dir = Path to directory where NR features and NR parameters are stored.
%
%   feature_function = Function call to compute the feature. 
%       This no-reference feature function (NRFF) must adhere to the
%       interface specified in calculate_NRpars.m.
%
%   action = string specifying the requested action:
%       'update_pars' = the 'pars' portion of 'feature_function' was
%                       updated. All NRpars.mat files will be removed and
%                       recalculated. Feature files will not be touched, so
%                       recalculating should be relatively fast.
%                       Note: the NRpars.mat files will be moved
%                       in sub-folder, 'previous_NRpars'.
%       'version' = the version of the NRMetricFramework library was
%                       updated. All NRpars.mat files must be updated.

    % Create a variable that has a path to this NRFF's directory
    if base_dir(length(base_dir)) ~= '\'
        base_dir = [base_dir '\'];
    end
    
    nrff_dir = [base_dir 'group_' feature_function('group') '\'];

    if ~exist(nrff_dir)
        error('NR parameter has not yet been calculated. Directory does not exist: %s', nrff_dir);
    end

    % update all NRpars.mat files that contain the old fields
    if strcmp(action,'version')
        
        list = ls([nrff_dir '*NRpars_*']);
        
        for cnt=1:size(list,1)
            parfile = [nrff_dir list(cnt,:)];
            
            try
                % Load previously calculated NR parameters
                load(parfile, 'NRpars');
                
                % if the NRpars variable has the version 1 field name
                % 'test", replace this with the version 2 field name
                % 'dataset_name' and overwrite.
                fields = fieldnames(NRpars);
                if strcmp(fields(5),'test') == 1
                    NRpars.dataset_name = NRpars.test;
                    NRpars = rmfield(NRpars,'test');
                    save (parfile, 'NRpars'); 
                end
                if isfield(NRpars, 'version') == 0
                    NRpars.version = 2;
                    save (parfile, 'NRpars'); 
                else
                    if NRpars.version <= 2;
                        NRpars.version = 2;
                        save (parfile, 'NRpars'); 
                    else
                        error('NR parameter version is greater than 2');
                    end
                end
                
            catch
                warning('Version update of NRpars file failed: %s', parfile);
            end
            
        end
        return;
    end

    % erase all NRpars.mat files
    if strcmp(action,'update_pars')
        mkdir([nrff_dir 'previous_NRpars'])
        
        list = ls([nrff_dir '*NRpars_*']);
        
        for cnt=1:size(list,1)
            parfile = [nrff_dir list(cnt,:)];
            move_parfile = [nrff_dir 'previous_NRpars\' list(cnt,:)];
            movefile(parfile, move_parfile);
        end
        return;
    end

    error('Action option not recognized');
end
    
    