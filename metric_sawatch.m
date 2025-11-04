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

        data{1} = 'S-Blur';          % from nrff_blur, combine 'unsharp' and 'viqet-sharpness'
        data{2} = 'S-FineDetail';    % from nrff_fine_detail
        data{3} = 'S-WhiteLevel';    % from nrff_auto enhancement
        data{4} = 'S-BlackLevel';    % from nrff_auto enhancement
        data{5} = 'S-ColorNoise';    % from nrff_peculiar_color
        data{6} = 'S-SuperSaturated'; % from nrff_peculiar_color
        data{7} = 'S-Pallid';        % from nrff_peculiar_color
        data{8} = 'S-Blockiness';    % from nrff_blockiness
        data{9} = 'S-PanSpeed';      % from nrff_panIPS
        data{10} = 'S-Jiggle';       % from nrff_panIPS
        data{11} = 'dipIQ';          % from reports/nrff_dipIQ
        data{12} = 'S-Noise';        % from nrff_fine_detail
        data{13} = 'S-Clipped';      % from nrff_fine_detail
        data{14} = 'S-Texture';      % from nrff_fine_detail

        data{15} = 'Sawatch_version_4';



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

            % Load Blur. 'unsharp' metric.
            tmp1 = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_blur);            

            % Use this to initialize NRpars variable, but erase irrelevant data
            NRpars = tmp1; 
            NRpars.par_name = par_name;
            NRpars.data = zeros(length(par_name),length(NRpars.media_name));
            
            % copy Blur metric, 'unsharp'
            NRpars.data(1,:) = tmp1.data(1,:); 

            % Fine Detail and Noise. 
            tmp1 = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_fine_detail);            
            NRpars.data(2,:) = tmp1.data(1,:); % more-or-less on this scale already 
            NRpars.data(12,:) = tmp1.data(2,:); % more-or-less on this scale already 
            NRpars.data(13,:) = tmp1.data(3,:); % more-or-less on this scale already 
            NRpars.data(14,:) = tmp1.data(4,:) ./ 0.85; % 0.85 scales values to [0..1] based on current datasets 

            % White Level and Black Level
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_auto_enhancement);
            
            % White Level: Scale to [0..1] where 0 = worst, then copy
            NRpars.data(3,:) = tmp.data(1,:); 
            
            % Black Level: already scaled
            NRpars.data(4,:) = tmp.data(2,:); 
            
            % load peculiar color pars
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_peculiar_color);
            
            % Color Noise 
            NRpars.data(5,:) = tmp.data(1,:); 
            
            % Super Saturation: already scaled
            NRpars.data(6,:) = tmp.data(2,:); 
            
            % Pallid: already scaled
            NRpars.data(7,:) = tmp.data(3,:); 
            
            % Blockiness
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_blockiness);
            NRpars.data(8,:) = tmp.data(1,:); 

            % Pan Speed
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_panIPS);
            NRpars.data(9,:) = tmp.data(1,:); 
            
            % Jiggle
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_panIPS);
            NRpars.data(10,:) = tmp.data(2,:); 

            % dipIQ 
            tmp = calculate_NRpars(nr_datasets(dcnt), base_dir, 'none', @nrff_dipIQ);
            NRpars.data(11,:) = tmp.data(1,:); 
            
            % rescale dipIQ to [0..1], where 0 is high quality, 1 is low
            % quality. Although outliers exist below -30 and above 0, these
            % are rare. 
            NRpars.data(11,:) = min(1, max(0, (-NRpars.data(11,:) / 30.0)));

            
            % - - - - -
            % Sawatch, version 4, begins here.
            % First, copy parameter values from above.
            % last element is the offset
            hold_pars = NRpars.data(1:14,:); 
            
            % add weights from linear regression
            % manually chose an optimal compromise across 12 datasets,
            % 6 IQA UGC, 3 VQA UGC, and 3 VQA broadcasting

            hold_pars(1,:) = hold_pars(1,:) * 2.40;
            hold_pars(2,:) = hold_pars(2,:).^2 * 1.3;
            hold_pars(3,:) = hold_pars(3,:) * 0.75 + hold_pars(3,:).^2 * 0.60; 
            hold_pars(4,:) = hold_pars(4,:) * 0.75;
            hold_pars(5,:) = hold_pars(5,:) * 1.8; 
            hold_pars(6,:) = hold_pars(6,:) * 0.15; 
            hold_pars(7,:) = hold_pars(7,:) * 0.15;
            hold_pars(8,:) = hold_pars(8,:) * 2.40; 
            hold_pars(9,:) = hold_pars(9,:) * 2.40; 
            hold_pars(10,:) = hold_pars(10,:) * 1.50; 
            hold_pars(11,:) = hold_pars(11,:).^2 * 3.00;
            hold_pars(12,:) = hold_pars(12,:) * 1.80;
            hold_pars(13,:) = hold_pars(13,:) * 0.75;  
            hold_pars(14,:) = hold_pars(14,:) * -0.25;  

            % Invert range and normalize to roughtly [5..1]
            sawatch = 6.2 - nansum(hold_pars);

            % clip lower end at zero. Anything below that is likely an
            % outlier. 
            NRpars.data(15,:) = max(0.0, sawatch);

            % Note version number
            NRpars.version = 4;

            % design flaws
            % CCRIQ MarthDanielPainting 
            %  --> camera flash impairment not detected
            % CCRIQ BeachToys MOS [1.5 to 4.5] but Sawatch [2.5 to 4]
            %  --> E and B and O = poor focus or double image
            %  --> maybe white background makes easier to see impairments?
            % CCRIQ Lady&Fence outliers MOS < 2 but Sawatch > 3.5
            % CCRIQ camera D, MOS < 2 but Sawatch [1 to 3.5], uncorrelated
            % CCRIQ cameras A, B, and G nearly as bad, narrow range of MOS
            %       and wide range of Sawatch
            % CID2013 C01 and C05 have outliers for MOS < 2 where Sawatch
            %       is unusually low
            % CV pipesnight has outliers for MOS < 3 where Sawatch is much
            %       lower than all other scenes
            %  --> only night scene
            %  --> scenes with a lot of white or a lot of black need more
            %      study. Non-linearities in luma may be causing inaccuracies. 
            % ITS4S2 category 6, infrared, has outliers for MOS < 3 and
            %       Sawatch < 2
            % ITS4S2 category 7, assault & fauna & fire have outliers for
            %       MOS < 3 and Sawatch < 2
            % ITSnoise Yemitas has inverse correlation, Sawatch to MOS
            %   --> pattern of marble counter, white/black noisy grain
            % ITS4S3 helmet has steeper angle, Sawatch to MOS, correlation
            %       is the same but different linear fit?
            % ITS4S 60fps, category 6, looks like need correction factor for
            %       60fps being higher quality, but ITS4S4 says 'no'
            %  --> explore relationship between fps and quality
            % AND HRCs, something but too complex for now

            save(fullfile(base_dir, ['\group_sawatch\NRpars_sawatch_' NRpars.dataset_name '.mat']), 'NRpars');
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

