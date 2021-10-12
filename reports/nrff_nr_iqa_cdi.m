function [data] = nrff_nr_iqa_cdi(mode, varargin)
% NRFF_BASIC_STATS
%   Calculate Basic 1-dimensional and 2-dimensional statistics to see if
%   they are appropriate for evaluating image and video quality
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
%
% SOFTWARE DISCLAIMER
% 
%  The algorithms implemented in this function were proposed in:
%
%  I. T. Ahmed, C. S. Der, N. Jamil and B. T. Hammad, Analysis of
%  Probability Density Functions in Existing No-Reference Image Quality
%  Assessment Algorithm for Contrast-Distorted Images, 2019 IEEE 10th
%  Control and System Graduate Research Colloquium (ICSGRC), Shah Alam,
%  Malaysia, 2019, pp. 133-137.

switch mode
    case 'group'
        data = 'NR-IQA-CDI';
    case 'feature_names'
        data{1} = 'mean';
        data{2} = 'std';
        data{3} = 'entropy';
        data{4} = 'kurtosis';
        data{5} = 'skewness';
    case 'parameter_names'
        data{1} = 'NR-IQA-CDI mean';
        data{2} = 'NR-IQA-CDI std';
        data{3} = 'NR-IQA-CDI entropy';
        data{4} = 'NR-IQA-CDI kurtosis';
        data{5} = 'NR-IQA-CDI skewness';
    case 'luma_only'
        data = true;
    case 'read_mode'
        data = 'si';
    case 'pixels'
        y = varargin{2};
        data{1,1} = mean(mean(y));
        data{1,2} = mean(std(y));
        %divide by 255 since the y-scale image values range from 0-255 to
        %represent 8 binary digits and the MATLAB entropy function takes
        %inputs in the range of 0-1
        entro = entropy(y/255);
        data{1,3} = entro;
        skew = mean(skewness(y));
        kurt = mean(kurtosis(y));
        data{1,4} = kurt;
        data{1,5} = skew;
    case 'pars'
        feature_data = varargin{1,1};
        %mean of all of the feature data taken for video inputs
        data(1) = mean(feature_data{1});
        data(2) = mean(feature_data{2});
        data(3) = mean(feature_data{3});
        data(4) = mean(feature_data{4});
        data(5) = mean(feature_data{5});
    otherwise
        error('Mode not recognized. Aborting.');
end