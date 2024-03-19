function [data] = nrff_2stepQA(mode, varargin)
% NRFF_2STEPQA
% No-Reference Feature Function (NRFF)
%
% Calculates the 2stepQA algorithm. 
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
%
% -----------COPYRIGHT NOTICE STARTS WITH THIS LINE------------
% 
% Copyright (c) 2019 The University of Texas at Austin
% 
% All rights reserved.Permission is hereby granted, without written
% agreement and without license or royalty fees, to use, copy, modify, and
% distribute this code (the source files) and its documentation for any
% purpose, provided that the copyright notice in its entirety appear in all
% copies of this code, and the original source of this code, Laboratory for
% Image and Video Engineering (LIVE, http://live.ece.utexas.edu) and Center
% for Perceptual Systems (CPS, http://www.cps.utexas.edu) at the University
% of Texas at Austin (UT Austin, http://www.utexas.edu), is acknowledged in
% any publication that reports research using this code. The research is to
% be cited in the bibliography as: 
% 
%     X. Yu, C. G. Bampis, P. Gupta and A. C. Bovik, "Predicting the
%     Quality of Images Compressed After Distortion in Two Steps", IEEE
%     Transactions on Image Processing, vol. 28, no. 12, pp. 5757-5770,
%     December 2019. [paper] URL: https://live.ece.utexas.edu/publications/2019/xiangxu2019tip.pdf   
%
%     X. Yu, C. G. Bampis, P. Gupta and A. C. Bovik, "Predicting the
%     Quality of Images Compressed After Distortion in Two Steps", Proc.
%     SPIE 10752, Applications of Digital Image Processing XLI, September
%     2018. [paper] URL: https://live.ece.utexas.edu/publications/2018/xiangxuyu2018spie.pdf   
%
%     X. Yu, C. G. Bampis, Praful Gupta and A. C. Bovik, "2stepQA Software
%     Release" URL: http://live.ece.utexas.edu/research/quality/2stepQA_release.zip, 2019 
%     X. Yu, C. G. Bampis, Praful Gupta and A. C. Bovik, "LIVE Wild
%     Compressed Picture Quality Database" URL: https://live.ece.utexas.edu/research/twostep/index.html, 2019 
% 
% IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN BE LIABLE TO ANY
% PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
% ARISING OUT OF THE USE OF THIS DATABASE AND ITS DOCUMENTATION, EVEN IF
% THE UNIVERSITY OF TEXAS AT AUSTIN HAS BEEN ADVISED OF THE POSSIBILITY OF
% SUCH DAMAGE. THE UNIVERSITY OF TEXAS AT AUSTIN SPECIFICALLY DISCLAIMS ANY
% WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE DATABASE
% PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF TEXAS AT
% AUSTIN HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
% ENHANCEMENTS, OR MODIFICATIONS.
% 
% -----------COPYRIGHT NOTICE ENDS WITH THIS LINE------------%
    switch mode
        case 'group'
            data = '2stepQA-NR';
        case 'feature_names'
            data{1} = '2stepQA-NR';
        case 'parameter_names'
            data{1} = '2stepQA-NR';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'parallelization'
            data = true; 
        case 'pixels'
            try
                load 2stepQA_modelparameters.mat
                y = varargin{2};
                y_temp = y;
                blocksizerow = 96;
                blocksizecol = 96;
                blockrowoverlap = 0;
                blockcoloverlap = 0;
                niqe = computequality(y,blocksizerow,blocksizecol,blockrowoverlap,blockcoloverlap,mu_prisparam,cov_prisparam);
                K = [0.01 0.03];
                winsize = 11;
                sigma = 1.5;
                window = fspecial('gaussian', winsize, sigma);
                level = 5;
                weight = [0.0448 0.2856 0.3001 0.2363 0.1333];
                method = 'product';
                msssim = ssim_mscale_new(y, y_temp, K, window, level, weight, 'product');

                two_stepQA = msssim*(1-niqe/100);
                data{1,1} = two_stepQA;
            catch
                data{1,1} = nan;
            end
        case 'pars'
            feature_data = varargin{1,1};
            data(1) = mean(feature_data{1});
        otherwise
            error('Mode not recognized. Aborting.');
    end
end

%---------------------------------------------------------------------
function  quality = computequality(im,blocksizerow,blocksizecol,...
    blockrowoverlap,blockcoloverlap,mu_prisparam,cov_prisparam)
   
% Input
% im              - Image whose quality needs to be computed
% blocksizerow    - Height of the blocks in to which image is divided
% blocksizecol    - Width of the blocks in to which image is divided
% blockrowoverlap - Amount of vertical overlap between blocks
% blockcoloverlap - Amount of horizontal overlap between blocks
% mu_prisparam    - mean of multivariate Gaussian model
% cov_prisparam   - covariance of multivariate Gaussian model

% For good performance, it is advisable to use make the multivariate Gaussian model
% using same size patches as the distorted image is divided in to

% Output
%quality      - Quality of the input distorted image

% Example call
%quality = computequality(im,96,96,0,0,mu_prisparam,cov_prisparam)

    % ---------------------------------------------------------------
    %Number of features
    % 18 features at each scale
    featnum      = 18;
    %----------------------------------------------------------------
    %Compute features
    if(size(im,3)==3)
    im               = rgb2gray(im);
    end
    im               = double(im);                
    [row col]        = size(im);
    block_rownum     = floor(row/blocksizerow);
    block_colnum     = floor(col/blocksizecol);

    im               = im(1:block_rownum*blocksizerow,1:block_colnum*blocksizecol);              
    [row col]        = size(im);
    block_rownum     = floor(row/blocksizerow);
    block_colnum     = floor(col/blocksizecol);
    im               = im(1:block_rownum*blocksizerow, ...
                       1:block_colnum*blocksizecol);               
    window           = fspecial('gaussian',7,7/6);
    window           = window/sum(sum(window));
    scalenum         = 2;
    warning('off')

    feat             = [];


    for itr_scale = 1:scalenum


    mu                       = imfilter(im,window,'replicate');
    mu_sq                    = mu.*mu;
    sigma                    = sqrt(abs(imfilter(im.*im,window,'replicate') - mu_sq));
    structdis                = (im-mu)./(sigma+1);



    feat_scale               = blkproc(structdis,[blocksizerow/itr_scale blocksizecol/itr_scale], ...
                               [blockrowoverlap/itr_scale blockcoloverlap/itr_scale], ...
                               @computefeature);
    feat_scale               = reshape(feat_scale,[featnum ....
                               size(feat_scale,1)*size(feat_scale,2)/featnum]);
    feat_scale               = feat_scale';


    if(itr_scale == 1)
    sharpness                = blkproc(sigma,[blocksizerow blocksizecol], ...
                               [blockrowoverlap blockcoloverlap],@computemean);
    sharpness                = sharpness(:);
    end


    feat                     = [feat feat_scale];

    im =imresize(im,0.5);

    end


    % Fit a MVG model to distorted patch features
    distparam        = feat;
    mu_distparam     = nanmean(distparam);
    cov_distparam    = nancov(distparam);

    % Compute quality
    invcov_param     = pinv((cov_prisparam+cov_distparam)/2);
    quality = sqrt((mu_prisparam-mu_distparam)* ...
        invcov_param*(mu_prisparam-mu_distparam)');

end


%---------------------------------------------------------------------
function feat = computefeature(structdis)

% Input  - MSCn coefficients
% Output - Compute the 18 dimensional feature vector 

    feat          = [];



    [alpha betal betar]      = estimateaggdparam(structdis(:));

    feat                     = [feat;alpha;(betal+betar)/2];

    shifts                   = [ 0 1;1 0 ;1 1;1 -1];

    for itr_shift =1:4

    shifted_structdis        = circshift(structdis,shifts(itr_shift,:));
    pair                     = structdis(:).*shifted_structdis(:);
    [alpha betal betar]      = estimateaggdparam(pair);
    meanparam                = (betar-betal)*(gamma(2/alpha)/gamma(1/alpha));                       
    feat                     = [feat;alpha;meanparam;betal;betar];

    end
end

%---------------------------------------------------------------------
function val = computemean(patch)

    val = mean2(patch);

end
%---------------------------------------------------------------------
function overall_mssim = ssim_mscale_new(img1, img2, K, window, level, weight, method)

% Multi-scale Structural Similarity Index (MS-SSIM)
% Z. Wang, E. P. Simoncelli and A. C. Bovik, "Multi-scale structural similarity
% for image quality assessment," Invited Paper, IEEE Asilomar Conference on
% Signals, Systems and Computers, Nov. 2003

    if (nargin < 2 | nargin > 7)
       overall_mssim = -Inf;
       return;
    end

    if (~exist('K'))
       K = [0.01 0.03];
    end

    if (~exist('window'))
       window = fspecial('gaussian', 11, 1.5);
    end

    if (~exist('level'))
       level = 5;
    end

    if (~exist('weight'))
       weight = [0.0448 0.2856 0.3001 0.2363 0.1333];
    end

    if (~exist('method'))
       method = 'product';
    end

    if (size(img1) ~= size(img2))
       overall_mssim = -Inf;
       return;
    end

    [M N] = size(img1);
    if ((M < 11) | (N < 11))
       overall_mssim = -Inf;
       return
    end

    if (length(K) ~= 2)
       overall_mssim = -Inf;
       return;
    end

    if (K(1) < 0 | K(2) < 0)
       overall_mssim = -Inf;
       return;
    end

    [H W] = size(window);

    if ((H*W)<4 | (H>M) | (W>N))
       overall_mssim = -Inf;
       return;
    end

    if (level < 1)
       overall_mssim = -Inf;
       return
    end


    min_img_width = min(M, N)/(2^(level-1));
    max_win_width = max(H, W);
    if (min_img_width < max_win_width)
       overall_mssim = -Inf;
       return;
    end

    if (length(weight) ~= level | sum(weight) == 0)
       overall_mssim = -Inf;
       return;
    end

    if (method ~= 'wtd_sum' & method ~= 'product')
       overall_mssim = -Inf;
       return;
    end

    downsample_filter = ones(2)./4;
    im1 = img1;
    im2 = img2;
    for l = 1:level
       [mssim_array(l) ssim_map_array{l} mcs_array(l) cs_map_array{l}] = ssim_index_new(im1, im2, K, window);
       [M N] = size(im1);
       filtered_im1 = filter2(downsample_filter, im1, 'valid');
       filtered_im2 = filter2(downsample_filter, im2, 'valid');
       clear im1, im2;
       im1 = filtered_im1(1:2:M-1, 1:2:N-1);
       im2 = filtered_im2(1:2:M-1, 1:2:N-1);
       ds_img_array1{l} = im1;
       ds_img_array2{l} = im2;
    end

    if (method == 'product')
    %   overall_mssim = prod(mssim_array.^weight);
       overall_mssim = prod(mcs_array(1:level-1).^weight(1:level-1))*mssim_array(level);
    else
       weight = weight./sum(weight);
       overall_mssim = sum(mcs_array(1:level-1).*weight(1:level-1)) + mssim_array(level);
    end

end

%---------------------------------------------------------------------
function [mssim, ssim_map, mcs, cs_map] = ssim_index_new(img1, img2, K, window)

    if (nargin < 2 | nargin > 4)
       ssim_index = -Inf;
       ssim_map = -Inf;
       return;
    end

    if (size(img1) ~= size(img2))
       ssim_index = -Inf;
       ssim_map = -Inf;
       return;
    end

    [M N] = size(img1);

    if (nargin == 2)
       if ((M < 11) | (N < 11))
           ssim_index = -Inf;
           ssim_map = -Inf;
          return
       end
       window = fspecial('gaussian', 11, 1.5);	%
       K(1) = 0.01;										% default settings
       K(2) = 0.03;										%
    end

    if (nargin == 3)
       if ((M < 11) | (N < 11))
           ssim_index = -Inf;
           ssim_map = -Inf;
          return
       end
       window = fspecial('gaussian', 11, 1.5);
       if (length(K) == 2)
          if (K(1) < 0 | K(2) < 0)
               ssim_index = -Inf;
            ssim_map = -Inf;
            return;
          end
       else
           ssim_index = -Inf;
        ssim_map = -Inf;
           return;
       end
    end

    if (nargin == 4)
       [H W] = size(window);
       if ((H*W) < 4 | (H > M) | (W > N))
           ssim_index = -Inf;
           ssim_map = -Inf;
          return
       end
       if (length(K) == 2)
          if (K(1) < 0 | K(2) < 0)
               ssim_index = -Inf;
            ssim_map = -Inf;
            return;
          end
       else
           ssim_index = -Inf;
        ssim_map = -Inf;
           return;
       end
    end

    C1 = (K(1)*255)^2;
    C2 = (K(2)*255)^2;
    window = window/sum(sum(window));

    mu1   = filter2(window, img1, 'valid');
    mu2   = filter2(window, img2, 'valid');
    mu1_sq = mu1.*mu1;
    mu2_sq = mu2.*mu2;
    mu1_mu2 = mu1.*mu2;
    sigma1_sq = filter2(window, img1.*img1, 'valid') - mu1_sq;
    sigma2_sq = filter2(window, img2.*img2, 'valid') - mu2_sq;
    sigma12 = filter2(window, img1.*img2, 'valid') - mu1_mu2;

    if (C1 > 0 & C2 > 0)
       ssim_map = ((2*mu1_mu2 + C1).*(2*sigma12 + C2))./((mu1_sq + mu2_sq + C1).*(sigma1_sq + sigma2_sq + C2));
       cs_map = (2*sigma12 + C2)./(sigma1_sq + sigma2_sq + C2);
    else
       numerator1 = 2*mu1_mu2 + C1;
       numerator2 = 2*sigma12 + C2;
        denominator1 = mu1_sq + mu2_sq + C1;
       denominator2 = sigma1_sq + sigma2_sq + C2;

       ssim_map = ones(size(mu1));
       index = (denominator1.*denominator2 > 0);
       ssim_map(index) = (numerator1(index).*numerator2(index))./(denominator1(index).*denominator2(index));
       index = (denominator1 ~= 0) & (denominator2 == 0);
       ssim_map(index) = numerator1(index)./denominator1(index);

       cs_map = ones(size(mu1));
       index = denominator2 > 0;
       cs_map(index) = numerator2(index)./denominator2(index);
    end

    mssim = mean2(ssim_map);
    mcs = mean2(cs_map);

    return
end

%---------------------------------------------------------------------

function [alpha betal betar] = estimateaggdparam(vec)


    gam   = 0.2:0.001:10;
    r_gam = ((gamma(2./gam)).^2)./(gamma(1./gam).*gamma(3./gam));


    leftstd            = sqrt(mean((vec(vec<0)).^2));
    rightstd           = sqrt(mean((vec(vec>0)).^2));

    gammahat           = leftstd/rightstd;
    rhat               = (mean(abs(vec)))^2/mean((vec).^2);
    rhatnorm           = (rhat*(gammahat^3 +1)*(gammahat+1))/((gammahat^2 +1)^2);
    [min_difference, array_position] = min((r_gam - rhatnorm).^2);
    alpha              = gam(array_position);

    betal              = leftstd *sqrt(gamma(1/alpha)/gamma(3/alpha));
    betar              = rightstd*sqrt(gamma(1/alpha)/gamma(3/alpha));

end
%---------------------------------------------------------------------
