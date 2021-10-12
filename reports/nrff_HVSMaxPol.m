function [data] = nrff_HVSMaxPol(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the HVS-MaxPol algorithm from:
%
% M. S. Hosseini, Y. Zhang and K. N. Plataniotis, "Encoding Visual
% Sensitivity by MaxPol Convolution Filters for Image Sharpness
% Assessment," in IEEE Transactions on Image Processing, vol. 28, no. 9,
% pp. 4510-4525, Sept. 2019, doi: 10.1109/TIP.2019.2906582.
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
% 
%   Copyright (c) 2018 Mahdi S. Hosseini
%
%   University of Toronto
%   The Edward S. Rogers Sr. Department of,
%   Electrical and Computer Engineering (ECE)
%   Toronto, ON, M5S3G4, Canada
%   Tel: +1 (416) 978 6845
%   email: mahdi.hosseini@mail.utoronto.ca

    switch mode
        case 'group'
            data = 'HVS-MaxPol';
        case 'feature_names'
            data{1} = 'HVS-MaxPol-1natural';
            data{2} = 'HVS-MaxPol-2natural';
            data{3} = 'HVS-MaxPol-1synthetic';
            data{4} = 'HVS-MaxPol-2synthetic';
        case 'parameter_names'
            data{1} = 'HVS-MaxPol-1natural';
            data{2} = 'HVS-MaxPol-2natural';
            data{3} = 'HVS-MaxPol-1synthetic';
            data{4} = 'HVS-MaxPol-2synthetic';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'pixels'
            % scores 1 and 2 used the 'natural' form and scores 3 and 4 used
            % the 'synthetic' form

            % scores 1 and 3 were used with one kernel and scores 2 and 4 were
            % used with two kernels
            y = varargin{2};
            load 'HVS_MaxPol_kernel.mat';
            params_HVS_MaxPol.kernel_sheets = selected_sheets;
            params_HVS_MaxPol.type = 'natural';
            params_HVS_MaxPol.numKernel = 1;
            score_1 = HVS_MaxPol(y, params_HVS_MaxPol);
            params_HVS_MaxPol.numKernel = 2;
            score_2 = HVS_MaxPol(y, params_HVS_MaxPol);
            params_HVS_MaxPol.type = 'synthetic';
            params_HVS_MaxPol.numKernel = 1;
            score_3 = HVS_MaxPol(y, params_HVS_MaxPol);
            params_HVS_MaxPol.numKernel = 2;
            score_4 = HVS_MaxPol(y, params_HVS_MaxPol);
            data{1,1} = score_1;
            data{1,2} = score_2;
            data{1,3} = score_3;
            data{1,4} = score_4;
        case 'pars'
            feature_data = varargin{1,1};
            data(1) = mean(feature_data{1});
            data(2) = mean(feature_data{2});
            data(3) = mean(feature_data{3});
            data(4) = mean(feature_data{4});
            
            % Replace the very rare outlier below 0 with NaN. Not sure why
            % these values occur, but they make the HVSMaxPol parameters
            % difficult to analyze.
            for cnt=1:4
                if data(cnt) < 0
                    data(cnt) = NaN;
                end
            end
        otherwise
            error('Mode not recognized. Aborting');
    end
end    
   

function [score] = HVS_MaxPol(input_image, params)
%
%Non-reference Image Sharpness Assessment (NR-ISA) metric for natural and
%synthetic images
%
%   [score] = HVS_MaxPol(input_image, params)
%
%   returns the NR-ISA score of the input image. Higher score indicates
%   more blurriness in the input image.
%
%
%   Input(s):
%   'input_image'           the grayscale input image for focus quality 
%                           assessment
%                   
%   'params.kernel_sheets'  the pre-designed human visual system kernel 
%                           that extracts the sharpness feature from the
%                           input image 
%
%   'params.type'           the blur type of the input image:
%                           (1) 'natural'
%                           (2) 'synthetic'
%
%   'params.numKernel'      the number of kernels used for focus quality
%                           measure
%                           (1) '1': HVS-MaxPol-1
%                           (2) '2': HVS-MaxPol-2
%
%   Output(s):
%   'score'                 the NR-ISA score 
%
%
%   Copyright (c) 2018 Mahdi S. Hosseini
%
%   University of Toronto
%   The Edward S. Rogers Sr. Department of,
%   Electrical and Computer Engineering (ECE)
%   Toronto, ON, M5S3G4, Canada
%   Tel: +1 (416) 978 6845
%   email: mahdi.hosseini@mail.utoronto.ca

    if strcmp(params.type,'natural') == 1 && params.numKernel == 2
        selected_kernels = params.kernel_sheets;
        momt = [6,2];
        weights = [0.3874; 4.0865];
    elseif strcmp(params.type,'synthetic') == 1 && params.numKernel == 2
        selected_kernels = params.kernel_sheets;
        momt = [10,6];
        weights = [0.3341; -0.1195];
    elseif strcmp(params.type,'natural') == 1 && params.numKernel == 1
        selected_kernels = params.kernel_sheets(1);
        momt = 6;
        weights = 1;    
    elseif strcmp(params.type,'synthetic') == 1 && params.numKernel == 1
        selected_kernels = params.kernel_sheets(1);
        momt = 10;
        weights = 1;
    else 
        disp('Error!')
    end

    [iB] = image_background(input_image); 

    if sum(iB(:)) > 0 % background check
        % load kernel
        for iteration_kernel = 1: numel(selected_kernels)
            % MaxPol variational decomposition
            i_BP_v = imfilter(input_image, selected_kernels{iteration_kernel}(:), 'symmetric', 'conv');
            i_BP_h = imfilter(input_image, selected_kernels{iteration_kernel}(:)', 'symmetric', 'conv');

            % Rectified Linear Unit operation
            mask = iB & (i_BP_v>0) & (i_BP_h>0);
            v = [abs(i_BP_v(mask)), abs(i_BP_h(mask))];

            [pdf, x] = histcounts(v(:), 50);
            cdf = cumsum(pdf)/sum(pdf);
            % find sigma approximate
            threshold = .95;
            min_val = min(cdf);
            max_val = max(cdf);
            rng_val = max_val - min_val;
            indx = cdf < min_val + threshold*rng_val;
            sigma_apprx = x(sum(indx))/max(x);
            c = (1-tanh(60*(sigma_apprx-.095)))/4 + 0.09;

            p_norm = 1/2;
            feature_map = (abs(v(:, 1)).^p_norm + abs(v(:, 2)).^p_norm).^(1/p_norm);

            %%
            number_of_pixels = round(c*numel(feature_map));
            feature_map = sort(feature_map(:), 'descend');
            feature_map = feature_map(1: number_of_pixels);

            %% iterate moments
            val = moment(feature_map, momt(iteration_kernel));
            val = abs(val);
            val = -log10(val);
            if val == (-inf)
                val = 0;
            elseif val == inf
                val = 120;
            end
            score(iteration_kernel) = val;
        end
        score = score * weights;
    else
        score = zeros(1, params.numKernel)*120;
        score = score * weights;
    end
    score = -score;
end

function [iB] = image_background(input_image)


    iB = input_image > .05;
    if false
        figure(1)
        subplot(1,3,2)
        img(input_image)

        subplot(1,3,3)
        img(iB)
        pause
    end

end