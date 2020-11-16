function [data] = nrff_agwn(mode, varargin)

% No-Reference Feature Function (NRFF)
%
%
% Calculates the Additive Gaussian White Noise (AGWN) metric as detailed 
% in the paper:
%   C. Lim and R. Paramesran, "Blind image quality assessment for color 
%   images with additive Gaussian white noise using standard deviation,"
%   2014 International Symposium on Intelligent Signal Processing and
%   Communication Systems (ISPACS), Kuching, 2014, pp. 039-041, doi:
%   10.1109/ISPACS.2014.7024421. 
%   https://ieeexplore.ieee.org/document/7024421
%
% Note that this paper calls the metric "proposed." 
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%

    switch mode

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % overall name of this group of NR features
        case 'group'

            data = 'agwn';

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % create NR feature names
        case 'feature_names'

            data{1} = 'stdR';
            data{2} = 'stdR8';
            data{3} = 'stdG';
            data{4} = 'stdG8';
            data{5} = 'stdB';
            data{6} = 'stdB8';


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % create NR parameter names (mean over time)
        case 'parameter_names'

            data{1} = 'AGWN';


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % color space
        case 'luma_only'

            data = false;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % calculate features on 1 frame
        case 'read_mode'

            data = 'si';


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'pixels'

           y = varargin{2};
           cb = varargin{3};
           cr = varargin{4};

           [r,g,b] = ycbcr2rgb_double(y,cb,cr, '128');

           data{1} = st_statistic('std', r, 'ST');
           data{3} = st_statistic('std', g, 'ST');
           data{5} = st_statistic('std', b, 'ST');

           data{2} = st_statistic('std', imresize(r, 0.5), 'ST');
           data{4} = st_statistic('std', imresize(g, 0.5), 'ST');
           data{6} = st_statistic('std', imresize(b, 0.5), 'ST');

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        case 'pars'

           % compute NR parameters
           feature_data = varargin{1,1};

           % not in paper: small constant to avoid divide by zero
           epsilon = 1E-20;

           % combine the results from each color plane (red, green, blue) using
           % the constants that convert the RGB color space to the YUV color
           % space. These are established in ITU-R Rec. BT.601.
           tmp = 0.299 * (feature_data{2} ./ feature_data{1} + epsilon) + ...
               0.587 * (feature_data{4} ./ feature_data{3} + epsilon) + ...
               0.114 * (feature_data{6} ./ feature_data{5} + epsilon);

           data(1) = nanmean(tmp);


           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        otherwise

            error('Mode not recognized. Aborting.');

    end

end %of function   