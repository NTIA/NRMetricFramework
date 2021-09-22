function [data] = nrff_og_iqa(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the OG-IQA algorithm from:
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% Calculates the OG-IQA score as detailed in the paper authored by Lixiong Liu, Yi Hua, Qingjie Zhao, Hua Huang, and Alan Conrad Bovik 
% "Blind Image Quality Assessment by Relative Gradient Statistics and AdaBoosting Neural Network".
% 
% Original software is linked in the wiki and lives at the following URL:
% Lixiong Liu, Yi Hua, Qingjie Zhao, Hua Huang, and Alan Conrad Bovik, "OG-IQA Software Release", 
% URL: http://live.ece.utexas.edu/research/quality/og-iqa_release.zip, 2015
%
% To execute this feature function, ensure that the folder "og-iqa_release"
% is downloaded and placed in the MATLAB project path. To download this
% folder, follow the directions in the wiki (TODO), or go to 
% URL: https://live.ece.utexas.edu/research/Quality/index_algorithms.htm
% and download the package labelled as "Blind image quality assessment by relative gradient statistics and Adaboosting neural network"
%


switch mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
case 'group'
    data = 'og_iqa';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
case 'feature_names'    
    data{1} = 'og_iqa_score';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
case 'parameter_names'
    data{1} = 'og_iqa_MEAN';
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
case 'luma_only'
    data = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
case 'read_mode'
    data = 'si';

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 'pixels'
    
   img = varargin{2};
   
   %data model supplied by UT
   load feature;
   
   features = feature_extract(img);
   
   data{1} = BP_Ada(f(:, [1,2,3,4,5,6]), f(:, 7), features, 10);
  
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 'pars'
    
   % compute NR parameters
   feature_data = varargin{1,1};

   data(1) = nanmean(squeeze(feature_data{1}));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
otherwise
  
    error('Mode not recognized. Aborting.');
    
end %of switch statement

end %of function   

   
