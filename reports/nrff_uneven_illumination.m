function [data] = nrff_uneven_illumination(mode, varargin)
% NRFF_UNEVEN_ILLUMINATION
%   Calculate an NR metric, for uneven illumination in the form of AGIC
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
% SOFTWARE DISCLAIMER / RELEASE
% 
% The algorithm implemented in this function was developed by the
% University of Texas at Austin. See their copyright notice, below. 
% 
% All other software on in this function was developed by employees of the
% National Telecommunications and Information Administration (NTIA), an
% agency of the Federal Government and is provided to you as a public
% service. Go to 'LICENSE.md' in the main directory of the NRMetricFramework
% repository for the NTIA SOFTWARE DISCLAIMER / RELEASE.
% 
% -----------COPYRIGHT NOTICE STARTS WITH THIS LINE------------
% Copyright (c) 2020 The University of Texas at Austin
% All rights reserved.
% 
% Permission is hereby granted, without written agreement and without
% license or royalty fees, to use, copy, modify, and distribute this code
% (the source files) and its documentation for any purpose, provided that
% the copyright notice in its entirety appear in all copies of this code,
% and the original source of this code, Laboratory for Image and Video
% Engineering (LIVE, http://live.ece.utexas.edu) and Center for Perceptual 
% Systems (CPS, http://www.cps.utexas.edu) at the University of Texas at 
% Austin (UT Austin, http://www.utexas.edu), is acknowledged in any 
% publication that reports research using this code. The research
% is to be cited in the bibliography as:
% 
% 1. F. Xie, Y. Lu, A. C. Bovik, Z. Jiang and R. Meng, Application-Driven
% No-Reference Quality Assessment for Dermoscopy Images With Multiple
% Distortions, IEEE Transactions on Biomedical Engineering, vol. 63, no. 6,
% pp. 1248-1256, June 2016.
% 
% IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN BE LIABLE TO ANY
% PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
% ARISING OUT OF THE USE OF THIS DATABASE AND ITS DOCUMENTATION, EVEN IF
% THE UNIVERSITY OF TEXAS AT AUSTIN HAS BEEN ADVISED OF THE POSSIBILITY OF
% SUCH DAMAGE.
% 
% THE UNIVERSITY OF TEXAS AT AUSTIN SPECIFICALLY DISCLAIMS ANY WARRANTIES,
% INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
% AND FITNESS FOR A PARTICULAR PURPOSE. THE DATABASE PROVIDED HEREUNDER IS
% ON AN "AS IS" BASIS, AND THE UNIVERSITY OF TEXAS AT AUSTIN HAS NO
% OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
% MODIFICATIONS.
% 
% -----------COPYRIGHT NOTICE ENDS WITH THIS LINE------------

switch mode
    case 'group'
        data = 'uneven_illumination';
        
    case 'feature_names'
        data{1} = 'AGIC';
        
    case 'parameter_names'
        data{1} = 'AGIC';
        
    case 'luma_only'
        data = true;
        
    case 'read_mode'
        data = 'si';
        
    case 'pixels'
        y = varargin{2};
        [row, col] = size(y);
        g = zeros(row, col);

        for i = 1:row %constructing g matrix using algorithm from dermoscopy article
            for j = 1:col %article link: https://ieeexplore.ieee.org/document/7302538
               if i == 1
                   meanCenter = mean(y(i,j)); %variable to prevent recomputations
                   if j == 1 %top left corner
                       temp(1) = abs(meanCenter - mean(y(i+1,j)));
                       temp(2) = abs(meanCenter - mean(y(i+1,j+1)));
                       temp(3) = abs(meanCenter - mean(y(i,j+1)));
                       g(i,j) = max(temp)/meanCenter;
                   elseif j == col %top right corner
                       temp(1) = abs(meanCenter - mean(y(i+1,j)));
                       temp(2) = abs(meanCenter - mean(y(i+1,j-1)));
                       temp(3) = abs(meanCenter - mean(y(i,j-1)));
                       g(i,j) = max(temp)/meanCenter;
                   else %anywhere on the top row
                       temp(1) = abs(meanCenter - mean(y(i,j-1)));
                       temp(2) = abs(meanCenter - mean(y(i+1,j-1)));
                       temp(3) = abs(meanCenter - mean(y(i+1,j)));
                       temp(4) = abs(meanCenter - mean(y(i+1,j+1)));
                       temp(5) = abs(meanCenter - mean(y(i,j+1)));
                       g(i,j) = max(temp)/meanCenter;
                   end
               elseif i == row
                   if j == 1 %bottom left corner
                       temp(1) = abs(meanCenter - mean(y(i-1,j)));
                       temp(2) = abs(meanCenter - mean(y(i-1,j+1)));
                       temp(3) = abs(meanCenter - mean(y(i,j+1)));
                       g(i,j) = max(temp)/meanCenter;
                   elseif j == col %bottom right corner
                       temp(1) = abs(meanCenter - mean(y(i-1,j)));
                       temp(2) = abs(meanCenter - mean(y(i-1,j-1)));
                       temp(3) = abs(meanCenter - mean(y(i,j-1)));
                       g(i,j) = max(temp)/meanCenter;
                   else %anywhere on the bottom row
                       temp(1) = abs(meanCenter - mean(y(i,j-1)));
                       temp(2) = abs(meanCenter - mean(y(i-1,j-1)));
                       temp(3) = abs(meanCenter - mean(y(i-1,j)));
                       temp(4) = abs(meanCenter - mean(y(i-1,j+1)));
                       temp(5) = abs(meanCenter - mean(y(i,j+1)));
                       g(i,j) = max(temp)/meanCenter;
                   end
               elseif j == 1 %anywhere on left col except for corners
                   temp(1) = abs(meanCenter - mean(y(i-1,j)));
                   temp(2) = abs(meanCenter - mean(y(i-1,j+1)));
                   temp(3) = abs(meanCenter - mean(y(i,j+1)));
                   temp(4) = abs(meanCenter - mean(y(i+1,j+1)));
                   temp(5) = abs(meanCenter - mean(y(i+1,j)));
                   g(i,j) = max(temp)/meanCenter;
               elseif j == col %anywhere on right col except for corners
                   temp(1) = abs(meanCenter - mean(y(i-1,j)));
                   temp(2) = abs(meanCenter - mean(y(i-1,j-1)));
                   temp(3) = abs(meanCenter - mean(y(i,j-1)));
                   temp(4) = abs(meanCenter - mean(y(i+1,j-1)));
                   temp(5) = abs(meanCenter - mean(y(i+1,j)));
                   g(i,j) = max(temp)/meanCenter;
               else %anywhere besides the edge rows
                   temp(1) = abs(meanCenter - mean(y(i-1,j-1)));
                   temp(2) = abs(meanCenter - mean(y(i-1,j)));
                   temp(3) = abs(meanCenter - mean(y(i-1,j+1)));
                   temp(4) = abs(meanCenter - mean(y(i,j+1)));
                   temp(5) = abs(meanCenter - mean(y(i+1,j+1)));
                   temp(6) = abs(meanCenter - mean(y(i+1,j)));
                   temp(7) = abs(meanCenter - mean(y(i+1,j-1)));
                   temp(8) = abs(meanCenter - mean(y(i,j-1)));
                   g(i,j) = max(temp)/meanCenter;
               end
            end
        end

        sum = 0;

        for i = 1:row
            for j = 1:col
                sum = sum + g(i,j);
            end
        end
        data{1,1} = sum/(row*col);
        
    case 'pars'
        feature_data = varargin{1,1};
        data(1) = nanmean(squeeze(feature_data{1}));
        
    otherwise
        error('Mode not recognized. Aborting.');
end