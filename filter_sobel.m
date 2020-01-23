function [si] = filter_sobel(y)
% FILTER_SI_HV
%
%  Filters Y with the sobel function. 
%
% SYNTAX
%
%  [SI] = filter_sobel(Y)

% DESCRIPTION
%
%  [SI] = filter_sobel(Y)  Perceptually filters luminence image Y using 
%  the sobel filter.
%
%   SI is the same size as Y, and has a 1-wide border of pixels set to zero. 
%

% if pass in a time-slice of 2+ images, reshape into 2-D.
if ndims(y) == 3 
    must_reshape = 1;
    [row_size, col_size, time_size] = size(y);
    y = reshape(y, row_size, col_size * time_size);   
elseif ndims(y) == 2
    must_reshape = 0;
else
    error('Function ''filter_si_hv'' requires Y to be a 2-D or 3-D image');
end

%  Assign defaults
[row_size, col_size, time_size] = size(y);

%
if row_size < 3 || col_size < 3
    error('Function ''filter_sobel'' requires images to be at least 3x3');
end

s = [1 2 1; 0 0 0; -1 -2 -1];
horiz = conv2(y, s);
vert = conv2(y, s');

% Construct SI image
si = sqrt(horiz.^2 + vert.^2);

% discard extra pixels around edge
si = si(2:row_size+1, 2:col_size+1);

% reshape if needed.
if must_reshape == 1
    si = reshape(si,row_size,col_size/time_size,time_size);
end

si(1,:) = 0;
si(:,1) = 0;
si(row_size,:) = 0;
si(:,col_size) = 0;
