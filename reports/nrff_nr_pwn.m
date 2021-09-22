function [data] = nrff_nr_pwn(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the NR PWN algorithm. 
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
%
% Copyright Notice:
% Copyright (c) 2015-2016 Arizona Board of Regents. 
% All Rights Reserved.
% Contact: Lina Karam (karam@asu.edu) and Tong Zhu(zhu@asu.edu)  
% Image, Video, and Usability (IVU) Lab, ivulab.asu.edu
% Arizona State University
% This copyright statement may not be removed from this file or from 
% modifications to this file.
% This copyright notice must also be included in any file or product 
% that is derived from this source file. 
 
    switch mode
        case 'group'
            data = 'nr-pwn';
        case 'feature_names'
            data{1} = 'nr-pwn';
        case 'parameter_names'
            data{1} = 'nr-pwn';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'pixels'
            y = varargin{2};
            NR_PWN_metric = compute_NR_PWN(y);
            data{1,1} = NR_PWN_metric;
        case 'pars'
            feature_data = varargin{1,1};
            data(1) = mean(feature_data{1});
        otherwise
            error('Mode not recognized. Aborting.');
    end
end

%=====================================================================
% File: compute_NR_PWN.m
% Original code written by Tong Zhu
% IVU Lab (http://ivulab.asu.edu)
% description   : This function computes the NR_PWN metric 
%===================================================================== 
% Copyright Notice:
% Copyright (c) 2015-2016 Arizona Board of Regents. 
% All Rights Reserved.
% Contact: Lina Karam (karam@asu.edu) and Tong Zhu(zhu@asu.edu)  
% Image, Video, and Usability (IVU) Lab, ivulab.asu.edu
% Arizona State University
% This copyright statement may not be removed from this file or from 
% modifications to this file.
% This copyright notice must also be included in any file or product 
% that is derived from this source file. 
% 
% Redistribution and use of this code in source and binary forms, 
% with or without modification, are permitted provided that the 
% following conditions are met:  
% - Redistribution's of source code must retain the above copyright 
% notice, this list of conditions and the following disclaimer. 
% - Redistribution's in binary form must reproduce the above copyright 
% notice, this list of conditions and the following disclaimer in the 
% documentation and/or other materials provided with the distribution. 
% - The Image, Video, and Usability Laboratory (IVU Lab, 
% http://ivulab.asu.edu) is acknowledged in any publication that 
% reports research results using this code, copies of this code, or 
% modifications of this code.  
% The code and our papers are to be cited in the bibliography as:
%
% Tong Zhu and Lina Karam. "A no-reference objective image quality metric
% based on perceptually weighted local noise."
% EURASIP Journal on Image and Video Processing 2014.1 (2014): 1-8.
%
% DISCLAIMER:
% This software is provided by the copyright holders and contributors 
% "as is" and any express or implied warranties, including, but not 
% limited to, the implied warranties of merchantability and fitness for
% a particular purpose are disclaimed. In no event shall the Arizona 
% Board of Regents, Arizona State University, IVU Lab members, or 
% contributors be liable for any direct, indirect, incidental, special,
% exemplary, or consequential damages (including, but not limited to, 
% procurement of substitute goods or services; loss of use, data, or 
% profits; or business interruption) however caused and on any theory 
% of liability, whether in contract, strict liability, or tort 
% (including negligence or otherwise) arising in any way out of the use 
% of this software, even if advised of the possibility of such damage. 
%===================================================================== 
function [NR_PWN_metric]=compute_NR_PWN(I);
    alpha=0.25;
    [size_i,size_j]=size(I);

    % we use 32*32 block to estimate local noise,
    % if the size is not multiple of 32,
    % we need to extend the size of image to be multiple of 32

    block_size=32; % block size of estimating noise variance 
    extend_i=ceil(size_i/block_size)*block_size;
    extend_j=ceil(size_j/block_size)*block_size;

    extend_I(1:size_i,1:size_j)=I;
    extend_I(size_i+1:extend_i,1:size_j)=I(size_i-1:-1:2*size_i-extend_i,1:size_j);
    extend_I(1:extend_i,size_j+1:extend_j)=extend_I(1:extend_i,size_j-1:-1:2*size_j-extend_j);

    for m=1:1: extend_i/ block_size
        for n=1:1: extend_j/ block_size
          I_block= extend_I(m*block_size-block_size+1:m*block_size,n*block_size-block_size+1:n*block_size);
           temp_evar = evar(I_block);
           sigma_map(m*block_size-block_size+1:m*block_size,n*block_size-block_size+1:n*block_size)=ones(block_size,block_size)*(temp_evar.^0.5)/255;
         end 
    end

    noise_mat=sigma_map(1:size_i,1:size_j);
    Tjnd_extend = computeJND(extend_I/255);% 
    Tjnd=Tjnd_extend(1:size_i,1:size_j);
    Tjnd(find(Tjnd==0))=0.0032;
    NR_PWN_metric=sum(sum((1*noise_mat./Tjnd).^alpha))/size_i/size_j;

end

%=====================================================================
% File: compute128.m
% Created by Nabil Sadaka, Revised by Tong Zhu
% IVU Lab (http://ivulab.asu.edu)
% description   : This function computes the JND threshold for
% a region with a mean grayscale value of 128  
%===================================================================== 
% Copyright Notice:
% Copyright (c) 2015-2016 Arizona Board of Regents. 
% All Rights Reserved.
% Contact: Lina Karam (karam@asu.edu) and Tong Zhu(zhu@asu.edu)  
% Image, Video, and Usability (IVU) Lab, ivulab.asu.edu
% Arizona State University
% This copyright statement may not be removed from this file or from 
% modifications to this file.
% This copyright notice must also be included in any file or product 
% that is derived from this source file. 
% 
% Redistribution and use of this code in source and binary forms, 
% with or without modification, are permitted provided that the 
% following conditions are met:  
% - Redistribution's of source code must retain the above copyright 
% notice, this list of conditions and the following disclaimer. 
% - Redistribution's in binary form must reproduce the above copyright 
% notice, this list of conditions and the following disclaimer in the 
% documentation and/or other materials provided with the distribution. 
% - The Image, Video, and Usability Laboratory (IVU Lab, 
% http://ivulab.asu.edu) is acknowledged in any publication that 
% reports research results using this code, copies of this code, or 
% modifications of this code.  
% The code and our papers are to be cited in the bibliography as:
%
% Tong Zhu and Lina Karam. "A no-reference objective image quality metric
% based on perceptually weighted local noise."
% EURASIP Journal on Image and Video Processing 2014.1 (2014): 1-8.
%
% DISCLAIMER:
% This software is provided by the copyright holders and contributors 
% "as is" and any express or implied warranties, including, but not 
% limited to, the implied warranties of merchantability and fitness for
% a particular purpose are disclaimed. In no event shall the Arizona 
% Board of Regents, Arizona State University, IVU Lab members, or 
% contributors be liable for any direct, indirect, incidental, special,
% exemplary, or consequential damages (including, but not limited to, 
% procurement of substitute goods or services; loss of use, data, or 
% profits; or business interruption) however caused and on any theory 
% of liability, whether in contract, strict liability, or tort 
% (including negligence or otherwise) arising in any way out of the use 
% of this software, even if advised of the possibility of such damage. 
%===================================================================== 
function  T128  = compute128(H,W,Px,Py,N)
     Lmin = 0;
    %   Lmax = 100; %250
     Lmax = 174.07; %250;
     LT = 13.45;
    S0 = 94.7;
    aT = 0.649;
    af = 0.182;
    f0 = 6.78; 
    Lf = 300;
    K0 = 3.125;
    aK = 0.0706;
    LK = 300;
    M = 256;
    % Equation for L
    L = Lmin + 128*(Lmax -Lmin)/M;
    if (L<=LK)  
        K = K0*((L/LK)^aK);
    else
        K = K0;    
    end

    if (L<=Lf)
        fmin = f0*((L/Lf)^af);
    else
        fmin = f0;    
    end

    if (L<=LT)
        Tmin = (LT/S0)*((L/LT)^aT);
    else
        Tmin = L/S0;    
    end
    % Distance to screen
    D = 60; % in cm
    
    % Px screen resolution in x direction
    % Py screen resolution in y direction
    wx = 2*((atan(W/(2*D)))*180/pi)/Px;
    wy = 2*((atan(H/(2*D)))*180/pi)/Py;

    g10 = log10(Tmin) + K*(((log10(1/(2*N*wx))-log10(fmin)))^2);
    g01 = log10(Tmin) + K*(((log10(1/(2*N*wy))-log10(fmin)))^2);
    T10 = 10^g10;
    T01 = 10^g01;
    % check for the min

    if ((T10-T01)>0)
        T00 = T01;
    else
        T00=T10;
    end

    T128 = T00*M/(Lmax-Lmin);
end

%=====================================================================
% File: computeJND.m
% Created by Nabil Sadaka, Revised by Tong Zhu
% IVU Lab (http://ivulab.asu.edu)
% description   : This function computes the JND threshold per block for an image
%===================================================================== 
% Copyright Notice:
% Copyright (c) 2015-2016 Arizona Board of Regents. 
% All Rights Reserved.
% Contact: Lina Karam (karam@asu.edu) and Tong Zhu(zhu@asu.edu)    
% Image, Video, and Usability (IVU) Lab, ivulab.asu.edu
% Arizona State University
% This copyright statement may not be removed from this file or from 
% modifications to this file.
% This copyright notice must also be included in any file or product 
% that is derived from this source file. 
% 
% Redistribution and use of this code in source and binary forms, 
% with or without modification, are permitted provided that the 
% following conditions are met:  
% - Redistribution's of source code must retain the above copyright 
% notice, this list of conditions and the following disclaimer. 
% - Redistribution's in binary form must reproduce the above copyright 
% notice, this list of conditions and the following disclaimer in the 
% documentation and/or other materials provided with the distribution. 
% - The Image, Video, and Usability Laboratory (IVU Lab, 
% http://ivulab.asu.edu) is acknowledged in any publication that 
% reports research results using this code, copies of this code, or 
% modifications of this code.  
% The code and our papers are to be cited in the bibliography as:
%
% Tong Zhu and Lina Karam. "A no-reference objective image quality metric
% based on perceptually weighted local noise."
% EURASIP Journal on Image and Video Processing 2014.1 (2014): 1-8.
%
% DISCLAIMER:
% This software is provided by the copyright holders and contributors 
% "as is" and any express or implied warranties, including, but not 
% limited to, the implied warranties of merchantability and fitness for
% a particular purpose are disclaimed. In no event shall the Arizona 
% Board of Regents, Arizona State University, IVU Lab members, or 
% contributors be liable for any direct, indirect, incidental, special,
% exemplary, or consequential damages (including, but not limited to, 
% procurement of substitute goods or services; loss of use, data, or 
% profits; or business interruption) however caused and on any theory 
% of liability, whether in contract, strict liability, or tort 
% (including negligence or otherwise) arising in any way out of the use 
% of this software, even if advised of the possibility of such damage. 
%===================================================================== 
function [Tjnd]= computeJND(A)
    A = double(A);
    [m,n ] =size(A);

    rb = 8;
    rc = 8;
    Bproc = blkproc(A,[rb rc],@mean2);
    H = 29.5; % in cm
    W = 38.7; % in cm
    % Px screen resolution in x direction
    % Py in y direction
    Px = 1280;
    Py  = 1024;
    mblk = 8; % sliding 3x3 window
    T128 = compute128(H,W,Px,Py,mblk);

    % replicate the borders
    B = zeros(m+2,n+2);
    [mB,nB] = size(B);

    B(2:mB-1,2:nB-1) = A;
    B(1,:) = [0 A(1,:) 0];
    B(mB,:) = [0 A(m,:) 0];
    B(:,1) = [0 ;A(:,1); 0];
    B(:,nB) = [0 ;A(:,n) ;0];
    [gBx gBy] = gradient(B);
    grdB =sqrt( abs(gBx).^2 + abs(gBy).^2);
    maskext = zeros(mB,nB);
    for row = 2:mB-1
        for col = 2:nB-1
            diffmat = [(B(row,col) - B(row-1,col)) ...
            (B(row,col) - B(row+1,col)) ...
            (B(row,col) - B(row,col-1)) ...
            B(row,col) - B(row,col+1)];

            meanval = Bproc(ceil((row-1)/rb), ceil((col-1)/rc));

            thres  = T128*((meanval/(128))^(0.649));
            Tjnd(row-1,col-1)=thres;
        end
    end
end


function [y,w] = dctn(y,DIM,w)

%DCTN N-D discrete cosine transform.
%   Y = DCTN(X) returns the discrete cosine transform of X. The array Y is
%   the same size as X and contains the discrete cosine transform
%   coefficients. This transform can be inverted using IDCTN.
%
%   DCTN(X,DIM) applies the DCTN operation across the dimension DIM.
%
%   Class Support
%   -------------
%   Input array can be numeric or logical. The returned array is of class
%   double.
%
%   Reference
%   ---------
%   Narasimha M. et al, On the computation of the discrete cosine
%   transform, IEEE Trans Comm, 26, 6, 1978, pp 934-936.
%
%   Example
%   -------
%       RGB = imread('autumn.tif');
%       I = rgb2gray(RGB);
%       J = dctn(I);
%       imshow(log(abs(J)),[]), colormap(jet), colorbar
%
%   The commands below set values less than magnitude 10 in the DCT matrix
%   to zero, then reconstruct the image using the inverse DCT.
%
%       J(abs(J)<10) = 0;
%       K = idctn(J);
%       figure, imshow(I)
%       figure, imshow(K,[0 255])
%
%   See also IDCTN, DCT, DCT2.
%
%   -- Damien Garcia -- 2008/06, revised 2009/11
%   website: <a
%   href="matlab:web('http://www.biomecardio.com')">www.BiomeCardio.com</a>

% ----------
%   [Y,W] = DCTN(X,DIM,W) uses and returns the weights which are used by the
%   program. If DCTN is required for several large arrays of same size, the
%   weights can be reused to make the algorithm faster. A typical syntax is
%   the following:
%      w = [];
%      for k = 1:10
%          [y{k},w] = dctn(x{k},[],w);
%      end
%   The weights (w) are calculated during the first call of DCTN then
%   reused in the next calls.
% ----------

    error(nargchk(1,3,nargin))

    y = double(y);
    sizy = size(y);

    % Test DIM argument
    if ~exist('DIM','var'), DIM = []; end
    assert(~isempty(DIM) || ~isscalar(DIM),...
        'DIM must be a scalar or an empty array')
    assert(isempty(DIM) || DIM==round(DIM) && DIM>0,...
        'Dimension argument must be a positive integer scalar within indexing range.')

    % If DIM is empty, a DCT is performed across each dimension

    if isempty(DIM), y = squeeze(y); end % Working across singleton dimensions is useless
    dimy = ndims(y);

    % Some modifications are required if Y is a vector
    if isvector(y)
        dimy = 1;
        if size(y,1)==1
            if DIM==1, w = []; return
            elseif DIM==2, DIM=1;
            end
            y = y.';
        elseif DIM==2, w = []; return
        end
    end

    % Weighting vectors
    if ~exist('w','var') || isempty(w)
        w = cell(1,dimy);
        for dim = 1:dimy
            if ~isempty(DIM) && dim~=DIM, continue, end
            n = (dimy==1)*numel(y) + (dimy>1)*sizy(dim);
            w{dim} = exp(1i*(0:n-1)'*pi/2/n);
        end
    end

    % --- DCT algorithm ---
    if ~isreal(y)
        y = complex(dctn(real(y),DIM,w),dctn(imag(y),DIM,w));
    else
        for dim = 1:dimy
            if ~isempty(DIM) && dim~=DIM
                y = shiftdim(y,1);
                continue
            end
            siz = size(y);
            n = siz(1);
            y = y([1:2:n 2*floor(n/2):-2:2],:);
            y = reshape(y,n,[]);
            y = y*sqrt(2*n);
            y = ifft(y,[],1);
            y = bsxfun(@times,y,w{dim});
            y = real(y);
            y(1,:) = y(1,:)/sqrt(2);
            y = reshape(y,siz);
            y = shiftdim(y,1);
        end
    end

    y = reshape(y,sizy);

end


function noisevar = evar(y)

%EVAR   Noise variance estimation.
%   Assuming that the deterministic function Y has additive Gaussian noise,
%   EVAR(Y) returns an estimated variance of this noise.
%
%   Note:
%   ----
%   A thin-plate smoothing spline model is used to smooth Y. It is assumed
%   that the model whose generalized cross-validation score is minimal can
%   provide the variance of the additive noise. A few tests showed that
%   EVAR works very well with "not too irregular" functions.
%
%   Examples:
%   --------
%   % 1D signal
%   n = 1e6; x = linspace(0,100,n);
%   y = cos(x/10)+(x/50);
%   var0 = 0.02; % noise variance
%   yn = y + sqrt(var0)*randn(size(y));
%   evar(yn) % estimated variance
%
%   % 2D function
%   [x,y] = meshgrid(0:.01:1);
%   f = exp(x+y) + sin((x-2*y)*3);
%   var0 = 0.04; % noise variance
%   fn = f + sqrt(var0)*randn(size(f));
%   evar(fn) % estimated variance
%
%   % 3D function
%   [x,y,z] = meshgrid(-2:.05:2);
%   f = x.*exp(-x.^2-y.^2-z.^2);
%   var0 = 0.6; % noise variance
%   fn = f + sqrt(var0)*randn(size(f));
%   evar(fn) % estimated variance
%
%   % Other examples
%   Click <a href="matlab:web('http://www.biomecardio.com/matlab/evar.html')">here</a> for more examples
%
%   Note:
%   ----
%   EVAR is only adapted to evenly-gridded 1-D to N-D data.
%
%   See also VAR, STD, SMOOTHN
%
%   -- Damien Garcia -- 2008/04, revised 2010/03
%   website: <a
%   href="matlab:web('http://www.biomecardio.com')">www.BiomeCardio.com</a>

    error(nargchk(1,1,nargin));

    d = ndims(y);
    siz = size(y);
    S = zeros(siz);
    for i = 1:d
        siz0 = ones(1,d);
        siz0(i) = siz(i);
        S = bsxfun(@plus,S,cos(pi*(reshape(1:siz(i),siz0)-1)/siz(i)));
    end
    S = 2*(d-S(:));

    % N-D Discrete Cosine Transform of Y
    if exist('dctn','file')
        y = dctn(y);
        y = y(:);
    else
        error('MATLAB:evar:MissingFunction',...
            ['DCTN is required. Download <a href="matlab:web(''',...
            'http://www.biomecardio.com/matlab/dctn.html'')">DCTN</a>.'])
    end

    %
    S = S.^2; y = y.^2;

    % Upper and lower bounds for the smoothness parameter
    N = sum(siz~=1); % tensor rank of the y-array
    hMin = 1e-6; hMax = 0.99;
    sMinBnd = (((1+sqrt(1+8*hMax.^(2/N)))/4./hMax.^(2/N)).^2-1)/16;
    sMaxBnd = (((1+sqrt(1+8*hMin.^(2/N)))/4./hMin.^(2/N)).^2-1)/16;

    % Minimization of the GCV score
    fminbnd(@func,log10(sMinBnd),log10(sMaxBnd),optimset('TolX',.1));

    function score = func(L)
        % Generalized cross validation score
        M = 1-1./(1+10^L*S);
        noisevar = mean(y.*M.^2);
        score = noisevar/mean(M)^2;
    end

end
