function [data] = metric_sawatch(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement NR metric "sawatch" version 1.
% SYNTAX & SEMANTICS
%   mode 'group' and 'parameter_names' as per 'calculate_NRpars' interface specifications.
%   mode 'compose' called as:
%       metric_sawatch('compose', nr_datasets, base_dir);
%   calculate and save as a parameter.



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
        

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        error('"%s" mode missing. This metric function is non-compliant', mode);
    end

end

