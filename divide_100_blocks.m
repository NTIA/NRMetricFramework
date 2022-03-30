function [blocks] = divide_100_blocks(rows, cols, extra_row, extra_col)
% divide_100_blocks
%   Choose blocks that divide an image / video
% SYNTAX
%   [blocks] = divide_100_blocks(rows, cols)
%   [blocks] = divide_100_blocks(rows, cols, extra)
%   [blocks] = divide_100_blocks(rows, cols, extra_row, extra_col)
% SEMANTICS
%  The idealized goal is to divide the image into 100 squares. This
%  function makes compromises, based on the realities of an uneven valid
%  region. Blocks are rectangles, and some blocks may have more
%  pixels than others. Slightly fewer or greater than 100 blocks may be 
%  returned.
%
% Input variables
%   'rows'
%   'cols'          Size of the image displayed on the monitor.
%   'extra_row'     Extra number of pixels, above and below, must be available
%                   around all blocks. Defaults to 0.
%   'extra_col'     Extra number of pixels, left and right, must be available
%                   around all blocks. Defaults to 0.
%   'extra'         Special case: extra_row = extra_col.
%
% Output variables
%   'blocks'            An array length N, each element a structure 
%                       describing one block.
%   'blocks().pixels'   Number of pixels in this block
%   'blocks().top'      Top row of the block
%   'blocks().left'     Left column of the block
%   'blocks().bottom'   Bottom row of the block
%   'blocks().right'    Right column of the block

    % Check input arguments. Default to zero extra pixels above/below and
    % left/right.
    if nargin == 3
        extra_col = extra_row;
    elseif nargin == 2
        extra_col = 0;
        extra_row = 0;
    end
    if nargin < 2
        error('Must specify number of rows and columns in the image');
    end
    
    if rows < 20 || cols < 20 || extra_row < 0 || extra_col < 0
        error('Invalid request');
    end
    

%% ------------------------------------------------------------------------
    % discard the extra rows and columns from the total
    rows = rows - 2 * extra_row;
    cols = cols - 2 * extra_col;

    % Find number of pixels per side of a box that would divide image into 100 boxes 
    box_pixels = sqrt((rows * cols) / 100); 
    
    % convert that into the number of boxes vertically & horizontally
    num_horiz = cols / box_pixels;
    num_vert = rows / box_pixels;
    
    % try all rounding options
    option(1).num_horiz = floor(num_horiz);
    option(1).num_vert = floor(num_vert);
    option(1).blocks = option(1).num_horiz  * option(1).num_vert;

    option(2).num_horiz = ceil(num_horiz);
    option(2).num_vert = ceil(num_vert);
    option(2).blocks = option(2).num_horiz  * option(2).num_vert;

    option(3).num_horiz = floor(num_horiz);
    option(3).num_vert = ceil(num_vert);
    option(3).blocks = option(3).num_horiz  * option(3).num_vert;

    option(4).num_horiz = ceil(num_horiz);
    option(4).num_vert = floor(num_vert);
    option(4).blocks = option(4).num_horiz  * option(4).num_vert;
    
    % choose rounding that gets closest to 100 boxes
    dist = abs(100 - [option.blocks]);
    [~,want] = min(dist);
    
    num_horiz = option(want).num_horiz;
    num_vert = option(want).num_vert;
    
    % figure out pixels per block
    qrow = floor(rows/num_vert);
    qcol = floor(cols/num_horiz);
    
%% ------------------------------------------------------------------------

    blk = 1;
    for cnt1=0:num_vert-1
        for cnt2=0:num_horiz-1
            blocks(blk).top    = 1 + extra_row + qrow * cnt1;
            blocks(blk).left   = 1 + extra_col + qcol * cnt2;
            blocks(blk).bottom = 1 + extra_row + qrow * (cnt1+1) - 1;
            blocks(blk).right  = 1 + extra_col + qcol * (cnt2+1) - 1;

            if cnt1 == num_vert-1
                blocks(blk).bottom = rows + extra_row;
            end
            if cnt2 == num_horiz-1
                blocks(blk).right = cols + extra_col;
            end
            blocks(blk).pixels = (blocks(blk).right - blocks(blk).left + 1) * ...
                (blocks(blk).bottom - blocks(blk).top + 1);

            blk = blk + 1;
        end
    end

%% ------------------------------------------------------------------------

    

%     % debug print
%     fprintf('Image %d x %d\n', rows, cols);
%     fprintf('Extra_row = %d\n', extra_row);
%     fprintf('Extra_col = %d\n', extra_col);
%     
%     num_blocks = num_vert * num_horiz;
%     for blk = 1:num_blocks
%         fprintf('%2d = (%d,%d),(%d,%d) = %d x %d = %d pixels\n', blk, ...
%             blocks(blk).top, blocks(blk).left, blocks(blk).bottom, blocks(blk).right, ...
%             blocks(blk).bottom - blocks(blk).top + 1, blocks(blk).right - blocks(blk).left + 1, ...
%             blocks(blk).pixels);
%     end


end
