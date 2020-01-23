function [top, left, bottom, right] = valid_region_search_nosafety (y, min_top, min_left, min_bottom, min_right)
%VALID_REGION_SEARCH_NOSAFETY
%   This is a function that calculates a valid region for one image. That 
%   is, area that isn't a black border. Function aims to remove black
%   borders from videos. This calculation has no safety margin at the edge, 
%   and so will not work properly for old videos containing closed 
%   captioning in the overscan.
%
%USAGE
%   Function takes the Luma plane of the YCbCr image and outputs the valid
%   region coordinates.
%
%   y - the luma plane of the YCbCr frame or image.
%   min_top - the min value we'd like the top y value to be
%   min_left - the min value we'd like the top x value to be
%   min_bottom - the min value we'd like the bottom y value to be
%   min_right - the min value we'd like the bottom x value to be 
%
%   [top_corner_y, top_corner_x, bottom_corner_y, bottom_corner_x] =
%   valid_region_search_nosafety(y, 0, 0 , 0 , 0);
%
% SEMANTICS
%   In general, this function works by taking the average of the pixel
%   values of the rows and columns and taking the mode of the vector of
%   average row values and the mode of the average column values. The idea
%   is that in natural 'normal' video, the border will be uniform color and
%   rectangular at the top and bottom. In this way, the mode should then
%   capture the pixel value of the row and column if it is a border (it is
%   unlikely you will have lines of solid color in a normal video). 
%
%   The average column and row values are then compared to this mode value
%   to determine if each column or row is a border row or not. We start on
%   the outside and move inwards, stopping once the column/row value
%   deviates to far from the mode value.
%
%   Also, if a row is a solid black line, the std deviation should be low,
%   (close to 0, if not exactly 0), therefore we also put a std deviation
%   threshold to decide if each row/column is a border or not.


    
    % establish stopping points, if whole image is black
    [row,col] = size(y);
    if isnan(min_top)
        min_top = row/2-1;
        min_bottom = row/2+1;
        min_left = col/2-1;
        min_right = col/2+1;
    end

    % calculate average of each row and column
    avg_col = mean(y, 1);
    avg_row = mean(y, 2);
    
    
    % calculate std deviation of each row and column
    % Theoretically, this should be zero if it is a true black border, as
    % all the pixels will have the same value in a column/rows
    std_col = std(y);
    std_row = std(y,0,2);

    % set threshold for when to say the image is not black
    row_mean_threshold = ceil(mode(avg_row)) + 1;
    col_mean_threshold = ceil(mode(avg_col)) + 1;
    row_std_threshold = ceil(min(std_row));
    col_std_threshold = ceil(min(std_col));
    
    threshold = min(row_mean_threshold, col_mean_threshold);
    %stdDevThreshold = min(row_std_threshold, col_std_threshold);
    stdDevThreshold = min(row_std_threshold, col_std_threshold) + 0.5;
    
    % search for left side.
    left = 1;
    while left < min_left
        if avg_col(left) <= threshold && std_col(left) <= stdDevThreshold
            left = left + 1;
        else
            break;
        end
    end

    % search for top side.
    top = 1;
    while top < min_top
        if avg_row(top) <= threshold && std_row(top) <= stdDevThreshold
            top = top + 1;
        else
            break;
        end
    end

    % search for right side.
    right = col;
    while right > min_right
        if avg_col(right) <= threshold && std_col(right) <= stdDevThreshold
            right = right - 1;
        else
            break;
        end
    end

    % search for bottom side.
    bottom = row;
    while bottom > min_bottom
        if avg_row(bottom) <= threshold && std_row(bottom) <= stdDevThreshold
            bottom = bottom - 1;
        else
            break;
        end
    end
    
    %Symmetry Check
    if(abs((col - left) - right) > 50)
        right = col;
        left = 1;
    end
    
    if(abs((row - top) - bottom) > 50)
        bottom = row;
        top = 1;
    end
end
