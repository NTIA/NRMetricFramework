function [data] = nrff_niqe(mode, varargin)

% No-Reference Feature Function (NRFF)
%
%
% Calculates the NIQE score as detailed in the paper, "A. Mittal, R.
% Soundararajan and A. C. Bovik, "Making a Completely Blind Image Quality Analyzer", submitted to IEEE Signal Processing Letters, 2012.
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
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
% Copyright (c) 2011 The University of Texas at Austin
% All rights reserved.
% 
% Permission is hereby granted, without written agreement and without license or royalty fees, to use, copy, 
% modify, and distribute this code (the source files) and its documentation for
% any purpose, provided that the copyright notice in its entirety appear in all copies of this code, and the 
% original source of this code, Laboratory for Image and Video Engineering (LIVE, http://live.ece.utexas.edu)
% and Center for Perceptual Systems (CPS, http://www.cps.utexas.edu) at the University of Texas at Austin (UT Austin, 
% http://www.utexas.edu), is acknowledged in any publication that reports research using this code. The research
% is to be cited in the bibliography as:
% 
% 1) A. Mittal, R. Soundararajan and A. C. Bovik, "NIQE Software Release", 
% URL: http://live.ece.utexas.edu/research/quality/niqe.zip, 2012.
% 
% 2) A. Mittal, R. Soundararajan and A. C. Bovik, "Making a Completely Blind Image Quality Analyzer", submitted to IEEE Signal Processing Letters, 2012.
% 
% IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, 
% OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS DATABASE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF TEXAS
% AT AUSTIN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% THE UNIVERSITY OF TEXAS AT AUSTIN SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE DATABASE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS,
% AND THE UNIVERSITY OF TEXAS AT AUSTIN HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
% 
% -----------COPYRIGHT NOTICE ENDS WITH THIS LINE------------%


switch mode
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
case 'group'
    
    data = 'niqe';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
case 'feature_names'
    
    data{1} = 'niqe_score';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
case 'parameter_names'
    
    data{1} = 'NIQE_MEAN';
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
case 'luma_only'
    
    data = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
case 'read_mode'
    
    data = 'si';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tell calculate_NRpars to use parallel_mode
case 'parallelization'
    
    data = true; 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 'pixels'
    
   %this component is the y component of the YCbCr which is the luma/grayscale component of the image
   img = varargin{2}; 
   
    % Check for a black image (which would crash computequality)
    try
        %Calculate niqe score
        data{1} = niqe(img);
        
    catch
        data{1} = nan;
    end
   
   
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 'pars'
    
   % compute NR parameters
   feature_data = varargin{1,1};

   data(1) = nanmean(squeeze(feature_data{1}));

    
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
otherwise
    
    error('Mode not recognized. Aborting.');
    
end

end %of function   

   
