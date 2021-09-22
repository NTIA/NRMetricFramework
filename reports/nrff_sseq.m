function [data] = nrff_sseq(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the SSSEQ algorithm. 
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
%
% Calculates the SSEQ score as detailed in the paper, 
% L. Liu, B. Liu, H. Huang, and A.C. Bovik "No-reference image quality
% assessment based on spatial and spectral entropies,"
% Signal Processing: Image Communication, June 2014.
% 
% To calculate SSEQ score, go to URL:
% https://live.ece.utexas.edu/research/Quality/index_algorithms.htm 
% and download the software package under the title: "No-reference Image
% Quality Assessment based on Spatial and Spectral Entropies"
% Unzip and add the path to that the folder to the MATLAB path with
% function addpath. 
% 
% CRITICAL: In order for this function to execute within the ITS No
% Reference Metric Framework, the third line of the file 
% "feature_extract.m" from the SSEQ folder: imdist=rgb2gray(imdist);
% must be commented out. 
%
% Additionally, the tool LIBSVM "A Library for Support Vector Machines"
% must be downloaded and placed in the MATLAB path. Download the package at 
% URL: https://www.csie.ntu.edu.tw/~cjlin/libsvm/#download
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'sseq';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')
    
    data{1} = 'SSEQ';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'SSEQ';
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
elseif strcmp(mode, 'luma_only')
    data = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
elseif strcmp(mode, 'read_mode')
    data = 'si';

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pixels')

   img = varargin{2};
   
   data{1} = SSEQ(img);
   
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
   % compute NR parameters
   feature_data = varargin{1,1};

   data(1) = nanmean(squeeze(feature_data{1}));

    
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    
    error('Mode not recognized. Aborting.');
end

end %of function   

   
