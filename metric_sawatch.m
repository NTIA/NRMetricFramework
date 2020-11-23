function [data] = metric_sawatch(mode, varargin)
% METRIC_SAWATCH
%   Calculate an NR metric, Sawatch, version 2.0.
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

        data{1} = 'Blur';          % from nrff_blur, combine 'unsharp' and 'viqet-sharpness'
        data{2} = 'FineDetail';    % from nrff_fine_detail
        data{3} = 'WhiteLevel';    % from nrff_auto enhancement
        data{4} = 'BlackLevel';    % from nrff_auto enhancement
        data{5} = 'ColorNoise';    % from nrff_peculiar_color
        data{6} = 'SuperSaturated'; % from nrff_peculiar_color
        data{7} = 'Pallid';        % from nrff_peculiar_color
        data{8} = 'PanSpeed';      % from nrff_panIPS
        data{9} = 'Blockiness';    % from nrff_blockiness

        data{10} = 'Sawatch version 1';
        data{11} = 'Sawatch version 2';


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
        
        % for each parameter, adjust the range to be [0..1], where 0 = worst. 
        for dcnt = 1:length(nr_datasets)

            % Blur. This is based on a linear model, trained against MOS. 
            % combines two different blur / sharpness parameters.
            tmp1 = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_blur);            

            % initialize media names, data for this dataset
            NRpars = tmp1; 
            NRpars.par_name = par_name;
            NRpars.data = zeros(length(par_name),length(NRpars.media_name));
            
            % copy Blur metric
            NRpars.data(1,:) = 1 - ( (tmp1.data(1,:) - 0) / 4 + ...
            	 (tmp1.data(2,:) - 1.0) / 8.0) / 2; 

            % Fine Detail. 
            tmp1 = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_fine_detail);            
            NRpars.data(2,:) = tmp1.data(1,:); % more-or-less on this scale already 

            % White Level and Black Level
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_auto_enhancement);
            
            % White Level: Scale to [0..1] where 0 = worst, then copy
            NRpars.data(3,:) = 1 - (tmp.data(1,:) - 10) / 140; 
            
            % Black Level: already scaled
            NRpars.data(4,:) = tmp.data(2,:); 
            
            % load peculiar color pars
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_peculiar_color);
            
            % Color Noise: scale to [0..1]; 
            NRpars.data(5,:) = (0.9 - tmp.data(1,:)) / 0.9; 
            
            % Super Saturation: already scaled
            NRpars.data(6,:) = tmp.data(2,:); 
            
            % Pallid: already scaled
            NRpars.data(7,:) = tmp.data(3,:); 
            
            % Pan IPS
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_panIPS);
            NRpars.data(8,:) = 1 - (tmp.data(7,:) - 1) / 4; 
            
            % Blockiness
            % Divide Blockiness by 4.5 to rescale from native scale to
            % [0..1], based on values for the AND and vqegHVcuts datasets.
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_blockiness);
            NRpars.data(9,:) = tmp.data(1,:) * 4.5; 

            % Compute Sawatch, version 1.0
            %
            % These weights were established as a compromise between the
            % linear regression weights indicated by the following
            % datasets: BID, CCRIQ, CID2013, CCRIQ2+VIME1 (C&V), ITS4S2,
            % LIVE-Wild, ITS4S3, ITS4S4, KonViD-1K, and ITS4S.
            %
            % All MOSs were scaled from their native scale to [0..1], where
            % 0 is highest quality, to make it easier to create a model in
            % the form of (5 - parameters).
            NRpars.data(10,:) = 0.198 + ...
                0.25 *   NRpars.data(3,:) + ...
                0.46 *   NRpars.data(1,:) + ...
                0.70 *   NRpars.data(8,:);
            
            NRpars.data(10,:) = 5 - 4 * NRpars.data(10,:);
            

            % Sawatch, version 2.0, begins here.
            % First, copy parameter values from above.
            % last element is the offset
            hold_pars = NRpars.data(1:9,:); 
            
            % add weights from linear regression
            % manually chose an optimal compromise across IQA and VQA
            % camera datasets, plus its4s_dataset
            hold_pars(1,:) = hold_pars(1,:) * 0.80;
            hold_pars(2,:) = hold_pars(2,:) * 0.50; 
            hold_pars(3,:) = hold_pars(3,:) * 0.25;
            hold_pars(4,:) = hold_pars(4,:) * 0.25;
            hold_pars(5,:) = hold_pars(5,:) * 0.35; 
            hold_pars(6,:) = hold_pars(6,:) * 0.05;
            hold_pars(7,:) = hold_pars(7,:) * 0.05;
            hold_pars(8,:) = hold_pars(8,:) * 0.70; 
            hold_pars(9,:) = hold_pars(9,:) * 0.80; 
            
            sawatch = nansum(hold_pars);
            
            % The above ranges from about [0.34 .. 1.85]. 
            % However, there are a lot of outliers above and below. 
            % We will shift this down, clip, and then scale to [0 .. 1],
            % using a smaller range in the middle
            sawatch = max( 0, sawatch - 0.4 ) ./ 1.2;
            
            % flip model, so that parameter values are subtracted from 5,
            % which represents excellent quality. This way, people can
            % easily omit a parameter that is not relevant to their
            % application (or increase). Also, clip at 1 minimum (bad)
            NRpars.data(11,:) = max(1, 5 - sawatch .* 4); 
            
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

