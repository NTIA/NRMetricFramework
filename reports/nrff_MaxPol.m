function [data] = nrff_MaxPol(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the MaxPol algorithm from "Image Sharpness Metric Based on
% Maxpol Convolution Kernels," which can be downloaded from 
% [https://ieeexplore.ieee.org/abstract/document/8451488]
%
% MaxPol / Synthetic-MaxPol software originates from
% https://github.com/mahdihosseini/Synthetic-MaxPol
%
% Author:
% Mahdi S. Hosseini
% Email: mahdi.hosseini@mail.utoronto.ca
% http://www.dsp.utoronto.ca/~mhosseini/
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
%
% GNU General Public License v3.0
% 
% Permissions of this strong copyleft license are conditioned on making
% available complete source code of licensed works and modifications, which
% include larger works using a licensed work, under the same license.
% Copyright and license notices must be preserved. Contributors provide an
% express grant of patent rights.
%
%

    switch mode
        case 'group'
            data = 'MaxPol';
        case 'feature_names'
            data{1} = 'MaxPol';
        case 'parameter_names'
            data{1} = 'MaxPol';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'parallelization'
            data = true; 
        case 'pixels'
            y.data = varargin{2}; %.data added to follow syntax of writer of MaxPol.m
            load('MaxPol_kernel.mat');
            params.d = MaxPol_kernel;
            params.moment_evaluation = [72, 8];
            score = Synthetic_MaxPol(y, params);
            data{1,1} = score;
        case 'pars'
            feature_data = varargin{1,1};
            data(1) = mean(feature_data{1});
        otherwise
            error('Mode not recognized. Aborting');
    end
end

function [score] = Synthetic_MaxPol(input_block, params)

    %%
    input_image = input_block.data;
    [m, n] = size(input_image);
    N = m*n;

    %%
    d = params.d;
    moment_evaluation = params.moment_evaluation;
    score = 0;
    for n_ord = 1: numel(d)
        i_BP_v = imfilter(input_image, d{n_ord}', 'symmetric', 'conv');
        i_BP_h = imfilter(input_image, d{n_ord}, 'symmetric', 'conv');


        %%
        v = [abs(i_BP_v(:)); abs(i_BP_h(:))];
        [pdf, x] = histcounts(v, 150); % 250 for BID, 150 for CID
        pdf = normal(pdf);
        %
        cdf = cumsum(pdf)/sum(pdf);
        %  find sigma approximate
        threshold = .9;
        indx = cdf < threshold;
        try %added try catch since there were cases where indx was all zeros and thus not able to index x
            sigma_apprx = x(sum(indx))/max(x);
            %c = min(.45, 1 - min(.96, 8*sigma_apprx));
            c = (1-tanh(50*(sigma_apprx-.095)))/2*.41+.04;

            %%
            p_norm = 1/2;
            %p_norm = (443/sqrt(N))^6;
            feature_map = (abs(i_BP_h).^p_norm + abs(i_BP_v).^p_norm).^(1/p_norm);

            %%
            number_of_pixels = round(c*N);
            feature_map = sort(feature_map(:), 'descend');
            feature_map = feature_map(1: number_of_pixels);

            %%
            val = moment(feature_map, moment_evaluation(n_ord));
            val = -log10(val);
            score = score + val;
        catch
            score = nan;
        end
    end
    if score == Inf
        score = 120;
    end
end

function [i]=normal(i)
    i=(i-min(i(:)))./range(i(:));
end
