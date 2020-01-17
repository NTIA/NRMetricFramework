function [data] = metric_sawatch(mode, varargin)
% METRIC_SAWATCH
%   Calculate an NR metric, Sawatch.
% SYNTAX
%   [feature_group]     = feature_function('group')
%   [parameter_names]   = feature_function('parameter_names')
%   [read_mode]         = feature_function('read_mode')
%   [par_data]          = feature_function('compose', nr_dataset, base_dir);
% SEMANTICS
%   This is a variant of the no reference feature function (NRFF) defined
%   in function calculate_NRpars.m
%
%   Where NRFF takes as input images or videos and outputs NR features and  
%   NR parameters, this NR metric takes as input NR parameters and outputs
%   NR metrics. 
%
%   The 'group', 'parameter_names', and 'read_mode' modes are as 
%   defined in the 'calculate_NRpars' interface specifications.
%   However, 'read_mode' must return 'metric'.
%
%   The 'compose' mode calculates the NR metric and save this data as per an
%   NR parameter.



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % overall name of this group of NR features
    if strcmp(mode, 'group')
        data = 'sawatch';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create NR parameter names (mean over time)
    elseif strcmp(mode, 'parameter_names')

        data{1} = 'WhiteLevel';    % from nrff_auto enhancement
        data{2} = 'Blur';          % from nrff_blur, combine 'unsharp' and 'viqet-sharpness'
        data{3} = 'PanSpeed';      % from nrff_panIPS

        data{4} = 'Sawatch';


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % calculate this metric from parameters.
    elseif strcmp(mode, 'compose')
        
        nr_datasets = varargin{1};
        base_dir = varargin{2};
        
        tmp = metric_sawatch('parameter_names');
        for pcnt = 1:length(tmp)
            par_name{pcnt} = tmp{pcnt};
        end
        
        mkdir(base_dir,'group_sawatch');
        
        for dcnt = 1:length(nr_datasets)
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_auto_enhancement);
            NRpars = tmp; % media names, computed
            NRpars.par_name = par_name;
            NRpars.data = nan(length(par_name),length(NRpars.media_name));
            
            % linear model, trained against MOS scaled on [0..1] where 0 = worst 
            NRpars.data(1,:) = 1 - (tmp.data(1,:) - 10) / 140; % * -0.0018092;
            
            tmp1 = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_blur);            
            NRpars.data(2,:) = 1 - ( (tmp1.data(1,:) - 0) / 4 + ...
            	 (tmp1.data(2,:) - 1.0) / 8.0) / 2; 

            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_panIPS);
            NRpars.data(3,:) = 1 - (tmp.data(7,:) - 1) / 4; % * -0.20264; % take weight from its4s4 dataset
            
            NRpars.data(4,:) = 0.198 + ...
                0.25 *   NRpars.data(1,:) + ...
                0.46 *   NRpars.data(2,:) + ...
                0.70 *   NRpars.data(3,:);
            
            NRpars.data(4,:) = 5 - 4 * NRpars.data(4,:);
            
            save([base_dir '\group_sawatch\NRpars_sawatch_' NRpars.test '.mat'], 'NRpars');
        end
        
        % return the metric data
        data = NRpars;
        

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif strcmp(mode, 'read_mode')
        data = 'metric';
        
    elseif strcmp(mode, 'feature_names') || strcmp(mode, 'luma_only') || ...
            strcmp(mode, 'pixels') || strcmp(mode, 'pars')
        error('"%s" mode not defined for NR metrics, which are calculated from NR pars', mode);
    else
        error('"%s" mode missing or not recognized.', mode);
    end

end

