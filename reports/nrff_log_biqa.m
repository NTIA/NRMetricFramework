function [data] = nrff_log_biqa(mode, varargin)
% No-Reference Feature Function (NRFF)
% 
% The log-biqa code and variables were obtained from the University of Texas 
% Image and Video Engineering site:
% URL: https://live.ece.utexas.edu/research/Quality/index_algorithms.htm
% including Learned_SVR_model_on_LIVE.mat
%
% The publication mentioned below is available at:
% http://utw10503.utweb.utexas.edu/publications/2014/BIQAUsingGM-LoG.pdf
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
% Copyright (c) 2014 The University of Texas at Austin
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
%   W. Xue, X. Mou, L. Zhang, A.C. Bovik, and X. Feng, “Blind image
%   quality prediction using joint statistics of gradient magnitude and
%   laplacian features,” IEEE Transactions on Image Processing, vol. 23,
%   no. 11, pp. 4850-4862, November 2014.    
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
    
    data = 'log-biqa';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
case 'feature_names'
    
    data{1} = 'log-biqa_score';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
case 'parameter_names'
    
    data{1} = 'log-biqa_MEAN';
    

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
    
    im = varargin{2};
    im = im/256; % divide by 256 to set values in between 0 and 1 since Grad_LOG requires those values over 8 bit values to properly calculate a quality assessment
    feature = Grad_LOG_CP_TIP(im);
    feature_mat = feature;

    %% predict quality from the feature with the trained model

    % load the trained model on LIVE database, M3 by default

    load('Learned_SVR_model_on_LIVE.mat','LIVE_SVR_M3');

    svr_model = LIVE_SVR_M3;
    data{1} = svmpredict(0, feature_mat, svr_model);

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 'pars'
    
    feature_data = varargin{1,1};

    data(1) = nanmean(squeeze(feature_data{1}));
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
otherwise   
    error('Mode not recognized. Aborting.');
end

end %of function


%% Code below this line is from the University of Texas at Austin

function out = Grad_LOG_CP_TIP(imd)

% Grad_LOG_CP_TIP - measure the distortion degree of distorted image 'imd'
% based on the statistical properties of Gradient Magnitude and LOG
% resposne.

% inputs:
% imd - the distorted image (grayscale image, double type, 0~255)

% outputs:
% out(1:20): the two marginal distribution for GM and LOG response. 
% out(21:40): the independency distributions between GM and LOG response. 

% This is an implementation of the NR IQA algorithm in the following paper:
%  W. Xue, X. Mou, L. Zhang, Alan C. Bovik, and X. Feng, ¡°Blind Image Quality Prediction Using
% Joint Statistics of Gradient Magnitude and Laplacian Features,¡± submitted to 
% Trans. on Image Processing, IEEE.

sigma = 0.5;
[gx,gy] = gaussian_derivative(imd,sigma);
grad_im = sqrt(gx.^2+gy.^2);

window2 = fspecial('log', 2*ceil(3*sigma)+1, sigma);
window2 =  window2/sum(abs(window2(:)));
log_im = abs(filter2(window2, imd, 'same'));

ratio = 2.5; % default value 2.5 is the average ratio of GM to LOG on LIVE database
grad_im = abs(grad_im/ratio);

%Normalization
c0 = 4*0.05;
sigmaN = 2*sigma;
window1 = fspecial('gaussian',2*ceil(3*sigmaN)+1, sigmaN);
window1 = window1/sum(window1(:));
Nmap = sqrt(filter2(window1,mean(cat(3,grad_im,log_im).^2,3),'same'))+c0;
grad_im = (grad_im)./Nmap;
log_im = (log_im)./Nmap;
% remove the borders, which may be the wrong results of a convolution
% operation
h = ceil(3*sigmaN);
grad_im = abs(grad_im(h:end-h+1,h:end-h+1,:));
log_im = abs(log_im(h:end-h+1,h:end-h+1));

ctrs{1} = 1:10;ctrs{2} = 1:10;
% histogram computation
step1 = 0.20;
step2 = 0.20;
grad_qun = ceil(grad_im/step1);
log_im_qun = ceil(log_im/step2);

N1 = hist3([grad_qun(:),log_im_qun(:)],ctrs);
N1 = N1/sum(N1(:));
NG = sum(N1,2); NL = sum(N1,1);

alpha1 = 0.0001;
% condition probability: Grad conditioned on LOG
cp_GL = N1./(repmat(NL,size(N1,1),1)+alpha1);
cp_GL_H=  sum(cp_GL,2)';
cp_GL_H = cp_GL_H/sum(cp_GL_H);
% condition probability: LOG conditioned on Grad
cp_LG = N1./(repmat(NG,1,size(N1,2))+alpha1);
cp_LG_H = sum(cp_LG,1);
cp_LG_H = cp_LG_H/(sum(cp_LG_H));

out = [NG', NL, cp_GL_H,cp_LG_H];
end

function [gx,gy] = gaussian_derivative(imd,sigma)
window1 = fspecial('gaussian',2*ceil(3*sigma)+1+2, sigma);
winx = window1(2:end-1,2:end-1)-window1(2:end-1,3:end);winx = winx/sum(abs(winx(:)));
winy = window1(2:end-1,2:end-1)-window1(3:end,2:end-1);winy = winy/sum(abs(winy(:)));
gx = filter2(winx,imd,'same');
gy = filter2(winy,imd,'same');
end
