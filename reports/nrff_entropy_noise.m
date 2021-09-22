function [data] = nrff_entropy_noise(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the Entropy Noise, using the random scatter transform. 
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
%


switch mode
        case 'group'
            data = 'entropy_noise';
        case 'feature_names'
            data{1} = 'entropy_of_scattered_image';
            data{2} = 'blur_factor';
        case 'parameter_names'
            data{1} = 'entropy_noise';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'pixels'
            y = varargin{2};
            sum_q_sigma_s = 0;
            sum_blur_factor = 0;
            num_loops = 10; %for experimentation use varying values for number of loops, 10 is used arbitarily here
            for i = 1:10 
                y_transformed = RST(y, mean(std(y))); %performing transform with original image
                %rather than downscaling and reupscaling
                sum_q_sigma_s = sum_q_sigma_s + entropy(y_transformed/255);
                sum_blur_factor = sum_blur_factor + log(abs(y_transformed.^2) + 1);
            end
            average_q_sigma_s = sum_q_sigma_s/num_loops;
            q_sigma_s = average_q_sigma_s - entropy(y/255);
            C_B = 0.016; %arbitrary constant that varies with sigma_s, 0.016 is supposedly typical
            blur_factor = sum_blur_factor*C_B;
            blur_factor = mean(mean(blur_factor));
            data{1,1} = q_sigma_s;
            data{1,2} = blur_factor;
        case 'pars'
            feature_data = varargin{1,1};
            image_size = varargin{3};
            alpha = 1 - exp(-40*feature_data{1}/(image_size(1)*image_size(2)));
            %formula for alpha labeled in article: https://ieeexplore.ieee.org/document/7351187
            data = nanmean((feature_data{1} + alpha.*feature_data{2})/(image_size(1)*image_size(2)));
        otherwise
            error('Mode not recognized. Aborting.');
    end

end


function y = RST(x,sigma_s)
    %random scattering transform
    y = x;
    [row, col] = size(x);
    for i = 1:row
        z = (0:col-1) + sigma_s*randn(1,col);
        [o,i_s] = sort(z);
        y(i,:) = x(i,i_s);
    end
    for i = 1:col
        z = (0:row-1) + sigma_s*randn(1,row);
        [o,i_s] = sort(z);
        y(:,i) = x(i_s,i);
    end
end