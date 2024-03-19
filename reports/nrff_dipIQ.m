function [data] = nrff_dipIQ(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the dipIQ algorithm. 
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
% DIP Inferred Quality Index (dipIQ)
% Version 1.0
% Copyright(c) 2016 Kede Ma, Wentao Liu, Tongliang Liu, Zhou Wang and
% Dacheng Tao
% All Rights Reserved.
%
% ----------------------------------------------------------------------
% Permission to use, copy, or modify this software and its documentation
% for educational and research purposes only and without fee is hereby
% granted, provided that this copyright notice and the original authors'
% names appear on all copies and supporting documentation. This program
% shall not be used, rewritten, or adapted as the basis of a commercial
% software or hardware product without first obtaining permission of the
% authors. The authors make no representations about the suitability of
% this software for any purpose. It is provided "as is" without express
% or implied warranty.
%----------------------------------------------------------------------
% This is an implementation of dipIQ for opinion-unaware blind image 
% quality assessment (OU-BIQA).
% Please refer to the following paper:
%
% K. Ma et al., "dipIQ: Blind Image Quality Assessment by
% Learning-to-Rank Discriminable Image Pairs" submitted to 
% IEEE Transactions on Image Processing.
%----------------------------------------------------------------------
% CORNIA code information
% A lightweight feature extraction code of CORNIA 
% By Kede Ma Aug., 2016
%
% references:
% [1] P. Ye, J. Kumar, L. Kang and D. Doermann, "Unsupervised Feature Learning Framework for No-reference Image Quality Assessment", IEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2012. 
% [2] P. Ye and D. Doermann, "No-Reference Image Quality Assessment using Visual Codebooks", IEEE Trans. on Image Processing, vol.21, no.7, pp.3129-3138, July 2012.


    switch mode
        case 'group'
            data = 'dipIQ';
        case 'feature_names'
            data{1} = 'dip_image_quality';
        case 'parameter_names'
            data{1} = 'dip_image_quality';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'parallelization'
            data = true; 
        case 'pixels'
            y = varargin{2};
            q = dipIQ(y, 1);
            data{1,1} = q;
        case 'pars'
            feature_data = varargin{1,1};
            data(1) = mean(feature_data{1});
        otherwise
            error('Mode not recognized. Aborting');
    end
end


%------------------------------------------------------------------------
function q = dipIQ(img, seed)
% ========================================================================
% DIP Inferred Quality Index (dipIQ)
% Version 1.0
% Copyright(c) 2016 Kede Ma, Wentao Liu, Tongliang Liu, Zhou Wang and
% Dacheng Tao
% All Rights Reserved.
%
% ----------------------------------------------------------------------
% Permission to use, copy, or modify this software and its documentation
% for educational and research purposes only and without fee is hereby
% granted, provided that this copyright notice and the original authors'
% names appear on all copies and supporting documentation. This program
% shall not be used, rewritten, or adapted as the basis of a commercial
% software or hardware product without first obtaining permission of the
% authors. The authors make no representations about the suitability of
% this software for any purpose. It is provided "as is" without express
% or implied warranty.
%----------------------------------------------------------------------
% This is an implementation of dipIQ for opinion-unaware blind image 
% quality assessment (OU-BIQA).
% Please refer to the following paper:
%
% K. Ma et al., "dipIQ: Blind Image Quality Assessment by
% Learning-to-Rank Discriminable Image Pairs" submitted to 
% IEEE Transactions on Image Processing.
%
%
% Kindly report any suggestions or corrections to k29ma@uwaterloo.ca
%
%----------------------------------------------------------------------
%
% Input : (1) img: test image.
%         (2) seed: random seed for patch selection in CORNIA feature
%                   extraction.
% Output: (1) q: quality score.
%
% Usage:
%   Given a test image img
%
%   q = dipIQ(img, 1);
%
%========================================================================
f = cornia_feature(img, seed);
load normalizationParaCORNIA; %changed this to fit folder change for github repo
f = ( f -  trainMu ) ./ trainStd; 

%load ('./support functions/netPara');
load netPara; %same change as above for netPara.mat file
paraNum = size(netPara, 2);
for i = 1 : 2 : paraNum - 2
    f = max(0, f * netPara(i).value + netPara(i+1).value');
end
q =  f * netPara(i+2).value + netPara(i+3).value';
end



%----------------------------------------------------------------
function fv = cornia_feature(img, seed)
% A lightweight feature extraction code of CORNIA 
% By Kede Ma Aug., 2016
%
% references:
% [1] P. Ye, J. Kumar, L. Kang and D. Doermann, "Unsupervised Feature Learning Framework for No-reference Image Quality Assessment", IEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2012. 
% [2] P. Ye and D. Doermann, "No-Reference Image Quality Assessment using Visual Codebooks", IEEE Trans. on Image Processing, vol.21, no.7, pp.3129-3138, July 2012.
%--------------------------------------------------------------------------------
% load codebook
load('CSIQ_codebook_BS7.mat','codebook0');
D = codebook0;
% load whitening parameter
load('CSIQ_whitening_param.mat','M','P');
numPatch = 10000;
% convert to gray-scale image
if size(img,3)~=1,
    img = rgb2gray(img);
end
% patch extraction
[dim, Dsize] = size(D); % dim: dimension of local feature, Dsize: codebook size
BS = sqrt(dim);
patches = im2col(img,[BS, BS]); % one patch per column, sliding window with step size = 1
% for computation and memory problem, we perform downsampling here, sample
% 10000 patches
rng(seed);
J = randperm(size(patches,2));
patches = double(patches(:,J(1:min(numPatch,length(J)))));
% normalization
patches = bsxfun(@rdivide, bsxfun(@minus, patches, mean(patches)), sqrt(var(patches)+10));
% whitening
patches = bsxfun(@minus, patches', M) * P; % one sample per row
% soft encoding
fv = soft_encoding_func(D, patches);
end


function soft_fv = soft_encoding_func(D, fv)
D = bsxfun(@rdivide, D, sqrt(sum(D.^2)) + 1e-20);
z = fv * D;
z = [max(z,0), max(-z,0)];
soft_fv = max(z);
end







