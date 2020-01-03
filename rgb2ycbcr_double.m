function [varargout] = rgb2ycbcr_double(varargin)
% RGB2YCBCR_DOUBLE
%   Convert image from RGB space into YCbCr space
% SYNTAX
%   [ycbcr] = rgb2ycbcr_double(rgb);
%   [y, cb, cr] = rgb2ycbcr_double(r,g,b);
%   [...] = rgb2ycbcr_double(...,'Flag',...);
% DESCRIPTION
%  Takes 'rgb', an (M,N,3) RGB double precision image, and converts 
%  'rgb' into an YCbCr image, 'ycbcr'.  Alternately, each image plane may 
%  be passed separately, in 'r', 'g' and 'b' input arguments.  
%  By default, the return image format will be the same as the input image 
%  format (i.e., one variable vs each plane separately)
%
%  Nominal input Y values are on [16,235] and nominal input Cb and Cr values 
%  are on [16,240].  RGB values are on [0,255].  This routine does not
%  round final RGB values to the nearest integer.
%  
%  The following optional arguments may be specified: 
% 
%  '128'    Return Cb and Cr values on a range from -128 to 127. 
%           By default, Cb and Cr range from [0..255]
%  'img'    Input variable 'rgb' is in 'img' format, as per imread
%           (i.e., [0..1] instead of [0..255]
%  'ycbcr'  Return matrix size (M,N,3), where (:,:,1) contains the Y
%           plane, (:,:,2) Cb, and (:,:,3) Cr.
%  'y_cb_cr' Return Y, Cb and Cr planes in three separate variables, 
%           each size (M,N).
%
%
%   Reference: 
%     Charles Poynton ColorFAQ.pdf (page 15), available from www.poynton.com.
%



is_128 = 0;
is_img = 0;
want_y_cb_cr = 0;
want_ycbcr = 0;

%
num_images = 0;
num_flags = 0;
for cnt=1:nargin
    if isnumeric(varargin{cnt})
        num_images = num_images + 1;
    elseif ischar(varargin{cnt})
        num_flags = num_flags + 1;
    else
        error('input arguments to "rgb2ycbcr_double" are unrecognizable');
    end
end

if num_images == 1
    red = varargin{1}(:,:,1);
    green = varargin{1}(:,:,2);
    blue = varargin{1}(:,:,3);
    want_ycbcr = 1;
elseif num_images == 3
    red = varargin{1};
    green = varargin{2};
    blue = varargin{3};
    want_y_cb_cr = 1;
else
    error('unexpected number of image matrixes input to rgb2ycbcr_double');
end

% parse flags
for cnt = num_images+1:num_images+num_flags
    if strcmp(varargin{cnt},'128')
        is_128 = 1;
    elseif strcmp(varargin{cnt},'img')
        is_img = 1;
        red = red * 256;
        green = green * 256;
        blue = blue * 256;
    elseif strcmp(varargin{cnt},'ycbcr')
        want_y_cb_cr = 0;
        want_ycbcr = 1;
    elseif strcmp(varargin{cnt},'y_cb_cr')
        want_y_cb_cr = 1;
        want_ycbcr = 0;
    else
        error('input flag not recognized');
    end
end




%---------------------------------------
% This is inefficient code for debugging
if 0
    
    % Transformation for each pixel is given by:
    % [Y Cb Cr]' = a0 + a1 * [R G B]'; RGB on [0, 255]
    a0 = [16;128;128];  % Offset
    a1 = [65.481 128.553 24.966; -37.797 -74.203 112; 112 -93.786 -18.214]/255;  % Matrix

    ycbcr = repmat(a0,1,nr*nc) + a1*reshape(rgb,nr*nc,np)';
    ycbcr = reshape(ycbcr',nr,nc,np);

    % Clip at 0 and 255
    ycbcr1 = max(0, min(ycbcr, 255));
    
end
%---------------------------------------
    
    
% convert RGB to YCbCr
y =   16.0 +  ((65.481/255.0)*red) + ((128.553/255.0)*green) + ((24.966/255.0)*blue);
cb = 128.0 + ((-37.797/255.0)*red) + ((-74.203/255.0)*green) + ((112.0/255.0)*blue);
cr = 128.0 +   ((112.0/255.0)*red) + ((-93.786/255.0)*green) + ((-18.214/255.0)*blue);


% shift, if wanted
if is_128
    cb = cb - 128;
    cr = cr - 128;
end


% format return variables
if want_y_cb_cr
    varargout{1} = y;
    varargout{2} = cb;
    varargout{3} = cr;
else 
    [row,col] = size(red);
    ycbcr = nan(row,col,3);
    ycbcr(:,:,1) = y;
    ycbcr(:,:,2) = cb;
    ycbcr(:,:,3) = cr;
    
    varargout{1} = ycbcr;
end

