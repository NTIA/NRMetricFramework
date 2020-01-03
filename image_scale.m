function [y2] = image_scale(y, rows, cols, black_border)
% IMAGE_SCALE
%   Scale an image or video to a target display size
% SYNTAX
%   [y, cb, cr] = image_scale(y, rows, cols, black_border)
% SEMANTICS
%   Up-scale or down-scale an image to a target display size. 
%
%   y = image or video to be rescaled. Dimensions are y(rows,cols,time)
%       or y(rows,cols,planes)
%   rows = size of target display, rows
%   cols = size of target display, columns
%   black_border = boolean. True to add a black border if the aspect
%       ratio doesn't match. False to omit border, returning an image
%       that may be smaller either vertically or horizontally
%   y2 = returned image, scaled to display "full screen" on a monitor of the specified size.


[row,col,~]=size(y);

% 
if isnan(rows) || isnan(cols)
    rows = row;
    cols = col;
end


% convert to viewing resolution
if row ~= rows || cols ~= col
    curr_scale = row / col;
    if curr_scale >= rows / cols
        % center horizontally
        scale = rows / row;
    else
        % center vertically
        scale = cols / col;
    end


    y2 = imresize(y, scale);
else
    y2 = y;
end

[new_row,new_col,planes] = size(y2);
% scale failed; slightly too large; try again
if new_row > rows || new_col > cols
    if curr_scale >= rows / cols
        % center horizontally
        scale = rows / (row+1);
    else
        % center vertically
        scale = cols / (col+1);
    end
    
    y2 = imresize(y, scale);
    [new_row,new_col,~] = size(y2);
    
    % scale failed; slightly too large; try again
    if new_row > rows || new_col > cols
        error('scale failed');
    end
end


if black_border
    pad_y2 = zeros(rows, cols, planes); 
    if new_row == rows
        r1 = 1;
        r2 = rows;
    else
        r1 = floor((rows-new_row)/2);
        r1 = max(r1,1);
        r2 = r1 + new_row - 1;
    end
    if new_col == cols
        c1 = 1;
        c2 = cols;
    else
        c1 = floor((cols-new_col)/2);
        c1 = max(c1,1);
        c2 = c1 + new_col - 1;
    end
    pad_y2(r1:r2,c1:c2,:) = y2;
    
    y2 = pad_y2;
end


