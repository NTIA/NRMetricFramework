function [data] = nrff_border(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard function calls to calculate features that estimates
%  inappropriate, artificial, or artifact lines.
%
%  Two basic ideas are implemented. The first is measuring the gradients
%  between image blocks.
% 
%  The second is recording the gradient local, and computing a contour
%  rating value from the gradients.
% 
%  Interpretation of this algorithm is currently taken from "Multiscale 
%  Probabilistic Dithering for Suppressing Contour Artifacts in Digital 
%  Images" IEEE Transactions on Image Processing,Vol. 18, No. 9, 2009,
%  Sitaram Bhagavathy.
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'border';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')

    data{1} = 'contour_average';
    data{2} = 'contour_stddev';
    data{3} = 'contour_average_block';
    data{4} = 'contour_stddev_block';
    data{5} = 'above_75_percent_area_block_count';
    data{6} = 'above_75_percent_area_block_pixel_count';
    data{7} = 'above_75_percent_area_block_border_count';    
    data{8} = 'above_75_percent_area_block_all_border_count';    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names
elseif strcmp(mode, 'parameter_names')

    data{1} = 'BorderWeight';
    data{2} = 'AllBorderWeight';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
elseif strcmp(mode, 'luma_only')
    data = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
elseif strcmp(mode, 'read_mode')
    data = 'si';
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tell calculate_NRpars to use parallel_mode
elseif strcmp(mode, 'parallelization')
    data = true; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pixels')
    fps = varargin{1};
    y = varargin{2};

    [row,col,frames] = size(y);
    if frames ~= 1
        error('This feature must be given exactly 1 frame in the tslice function call');
    end
    
    % Truncate colors
    luma_truncate_size = 16;
    luma_count = ceil(256 / luma_truncate_size);

    % Get color gradients around center pixel, below is similar to the landmark fast 9:16 or brisk bit masks
    mask                   = ...
        [ ...
            0 1 1 1 0; ...
            1 0 0 0 1; ...
            1 0 6 0 1; ...
            1 0 0 0 1; ...
            0 1 1 1 0 ...
        ];
    [ mask_row, mask_col ] = size(mask);
    mask_xcenter           = ceil(mask_col / 2);
    mask_ycenter           = ceil(mask_row / 2);

    % Get adjacent and center color counts. This function counts the number 
    %     of times any given color occurs in same and adjacent cells.
    pixel_counts = zeros(row, col, luma_count);

    for y1=1:row
        for x1=1:col
            % For this pixel, set adjacent(and same) color count
            for y2=1:mask_row
                for x2=1:mask_col
                    x3 = x1+x2-mask_xcenter;
                    y3 = y1+y2-mask_ycenter;
                    if 1 <= x3 && x3 <= col && 1 <= y3 && y3 <= row
                        val = floor(y(y3, x3) / luma_truncate_size) + 1;
                        pixel_counts(y1, x1, val) = pixel_counts(y1, x1, val) + mask(y2, x2);
                    end
                end
            end
        end
    end

    % Get maximum rating of area being significant using equation from 
    %    CAMBI algorithm:  
    %    rating = max((p0 * p1) / (p0 + p1))
    %    where p0 is color count of center pixel
    %          p1 is color count of adjacent pixels
    % See below link for this equation:
    %    Interpretation of this algorithm is currently taken from 
    %      "Multiscale Probabilistic Dithering for Suppressing Contour
    %      Artifacts in Digital Images" IEEE Transactions on Image
    %      Processing, Vol. 18, No. 9, 2009, Sitaram Bhagavathy.
    c_val = zeros(row, col);

    for y1=1:row
        for x1=1:col
            val = floor(y(y1, x1) / luma_truncate_size) + 1;
            p0 = pixel_counts(y1, x1, val);

            for y2=1:mask_row
                for x2=1:mask_col
                    x3 = x1+x2-mask_xcenter;
                    y3 = y1+y2-mask_ycenter;
                    if 1 <= x3 && x3 <= col && 1 <= y3 && y3 <= row && p0 > 0
                        for c=1:luma_count
                            if c ~= val
                                p1 = pixel_counts(y3, x3, c);
                                c_val(y1, x1) = max(c_val(y1, x1), (p0 * p1) / (p0 + p1));
                            end
                        end
                    end
                end
            end
        end
    end

    % Write media to output file for testing purposes
    % bytes = zeros(row, col);
    % for y1=1:row
    %     for x1=1:col
    %         bytes(y1, x1) = max(0, min(255, round(255-c_val(y1, x1)*32)))/255;
    %     end
    % end
    % imwrite(bytes, 'temp_base.png');
    
    % Get stats for overall image
    data{1} = mean(c_val(:));
    data{2} =  std(c_val(:));

    % Divide the image into approximately 100 blocks. And, get average
    %   and deviation for each block.
    [blocks]      = divide_100_blocks(row, col, 0);
    blocks_count  = length(blocks);
    c_val_average = zeros(1, blocks_count);
    c_val_stddev  = zeros(1, blocks_count);
    
    for loop = 1:blocks_count
        c_val_block         = c_val(blocks(loop).top:blocks(loop).bottom, blocks(loop).left:blocks(loop).right);
        c_val_average(loop) = mean(c_val_block(:));
        c_val_stddev(loop)  =  std(c_val_block(:));
    end
    
    % Store values for blocks
    data{3} = c_val_average;
    data{4} = c_val_stddev ;

    % Place colors in different grouped areas and write image.
    %   Group by adjacent color differences of currently 
    %   around 5% or less.
    count_grouped_diff_ratio = 0.05;
    max_cval = sum(mask(:)) / 2; % Note is derived by p0 = p1 = total_max_mask_val such that p0 * p1 / (p0 + p1) = p0 / 2 = total_max_mask_val / 2
    
    gindex            =   zeros(row, col);
    gindex_count      =                 0;
    search_index_list = zeros(1, row*col);
    
    for y1=1:row
        for x1=1:col
            % Ignore this pixel if already part of a group
            if gindex(y1, x1) ~= 0
                continue
            end

            % Increment pixel group counter
            gindex_count = gindex_count + 1;

            % Start searching from this pixel
            search_index_list_count = 1;
            search_index_list(search_index_list_count) = (y1 - 1) * col + x1 - 1;

            % Iteratively search grid for adjacent pixels in sorted order. Iterates grid in down/up then left/right orientation
            while search_index_list_count > 0
                grid_indexes = unique(search_index_list(1:search_index_list_count));
                search_index_list_count = length(grid_indexes);
                search_index_list_index = 0;

                % Search leftmost/rightmost indexes of this pixel and set to a group
                for index=1:search_index_list_count
                    x2 =   mod(grid_indexes(index),  col) + 1;
                    y2 = floor(grid_indexes(index) / col) + 1;
                    % Ignore pixel if was already grouped
                    if gindex(y2, x2) ~= 0
                        continue
                    end

                    x = x2;
                    while x >   1 && gindex(y2, x-1) == 0 && abs(c_val(y2, x) - c_val(y2, x-1)) <= max_cval * count_grouped_diff_ratio
                        x = x - 1;
                    end
                    while 1
                        gindex(y2, x) = gindex_count;

                        % Add similar adjacent lower/upper row pixels for future iteration
                        if     x >   1 && y2 >   1 && gindex(y2-1, x-1) == 0 && abs(c_val(y2, x) - c_val(y2-1, x-1)) <= max_cval * count_grouped_diff_ratio
                            search_index_list_index = search_index_list_index + 1;
                            search_index_list(search_index_list_index) = (y2 - 2) * col + x - 2;
                        elseif            y2 >   1 && gindex(y2-1, x  ) == 0 && abs(c_val(y2, x) - c_val(y2-1, x  )) <= max_cval * count_grouped_diff_ratio
                            search_index_list_index = search_index_list_index + 1;
                            search_index_list(search_index_list_index) = (y2 - 2) * col + x - 1;
                        elseif x < col && y2 >   1 && gindex(y2-1, x+1) == 0 && abs(c_val(y2, x) - c_val(y2-1, x+1)) <= max_cval * count_grouped_diff_ratio
                            search_index_list_index = search_index_list_index + 1;
                            search_index_list(search_index_list_index) = (y2 - 2) * col + x    ;
                        elseif x >   1 && y2 < row && gindex(y2+1, x-1) == 0 && abs(c_val(y2, x) - c_val(y2+1, x-1)) <= max_cval * count_grouped_diff_ratio
                            search_index_list_index = search_index_list_index + 1;
                            search_index_list(search_index_list_index) =  y2      * col + x - 2;
                        elseif            y2 < row && gindex(y2+1, x  ) == 0 && abs(c_val(y2, x) - c_val(y2+1, x  )) <= max_cval * count_grouped_diff_ratio
                            search_index_list_index = search_index_list_index + 1;
                            search_index_list(search_index_list_index) =  y2      * col + x - 1;
                        elseif x < col && y2 < row && gindex(y2+1, x+1) == 0 && abs(c_val(y2, x) - c_val(y2+1, x+1)) <= max_cval * count_grouped_diff_ratio
                            search_index_list_index = search_index_list_index + 1;
                            search_index_list(search_index_list_index) =  y2      * col + x    ;
                        end

                        if ~(x < col && gindex(y2, x+1) == 0 && abs(c_val(y2, x) - c_val(y2, x+1)) <= max_cval * count_grouped_diff_ratio)
                            break;
                        end

                        x = x + 1;
                    end
                end

                search_index_list_count = search_index_list_index;
            end
        end
    end

    % Write media to output file for testing purposes
    % group_color_incr  = ceil(nthroot(gindex_count, 3));
    % group_color       = zeros(group_color_incr*group_color_incr*group_color_incr, 3);
    % group_color_count = 0;
    % for index1=1:group_color_incr
    %     for index2=1:group_color_incr
    %         for index3=1:group_color_incr
    %             group_color_count = group_color_count + 1;
    %             group_color(group_color_count, 1) = floor(index1 * 255 / group_color_incr);
    %             group_color(group_color_count, 2) = floor(index2 * 255 / group_color_incr);
    %             group_color(group_color_count, 3) = floor(index3 * 255 / group_color_incr);
    %         end
    %     end
    % end
    % group_color_order = randperm(group_color_count);    
    % group_color(:, 1) = group_color(group_color_order, 1);
    % group_color(:, 2) = group_color(group_color_order, 2);
    % group_color(:, 3) = group_color(group_color_order, 3);

    % bytes = zeros(row, col, 3);
    % for y1=1:row
    %     for x1=1:col
    %         bytes(y1, x1, 1) = max(0, min(1, group_color(gindex(y1, x1), 1)/255));
    %         bytes(y1, x1, 2) = max(0, min(1, group_color(gindex(y1, x1), 2)/255));
    %         bytes(y1, x1, 3) = max(0, min(1, group_color(gindex(y1, x1), 3)/255));
    %     end
    % end
    % imwrite(bytes, 'temp_group.png');

    % Count group area pixels
    gindex_pixel_count = zeros(1, gindex_count);
    for y1=1:row
        for x1=1:col
            hgindex = gindex(y1, x1);
            gindex_pixel_count(hgindex) = gindex_pixel_count(hgindex) + 1;
        end
    end

    % Count top groups that make up 75% or more of image area
    [ vals_count_top, gindex_val ] = sort(gindex_pixel_count, 'descend');
    area               = row * col;
    sub_area_min_ratio = 0.75;

    above_75_percent_area_count       = 0;
    above_75_percent_area_pixel_count = 0;

    while above_75_percent_area_count < gindex_count && above_75_percent_area_pixel_count < area * sub_area_min_ratio
        above_75_percent_area_count       = above_75_percent_area_count + 1;
        above_75_percent_area_pixel_count = above_75_percent_area_pixel_count + vals_count_top(above_75_percent_area_count);
    end

    % Flag area indexes that are significant
    is_large_area = zeros(1, gindex_count);

    for index=1:above_75_percent_area_count
        hgindex = gindex_val(index);
        is_large_area(hgindex) = 1;
    end

    % Divide image into blocks
    above_75_percent_area_block_count            = zeros(1, blocks_count);
    above_75_percent_area_block_pixel_count      = zeros(1, blocks_count);
    above_75_percent_area_block_border_count     = zeros(1, blocks_count);
    above_75_percent_area_block_all_border_count = zeros(1, blocks_count);

    for loop = 1:blocks_count
        for y1=blocks(loop).top:blocks(loop).bottom
            % Count number of pixels bordering a large image group area
            for x1=blocks(loop).left:blocks(loop).right
                above_75_percent_area_block_count(loop) = row*col;

                hgindex = gindex(y1, x1);

                % Count pixels bordering 2 large areas
                if is_large_area(hgindex) == 1 && (...
                    (y1 >   1 && x1 >   1 && gindex(y1-1, x1-1) ~= hgindex && is_large_area(gindex(y1-1, x1-1)) == 1) || ...
                    (y1 >   1 &&             gindex(y1-1, x1  ) ~= hgindex && is_large_area(gindex(y1-1, x1  )) == 1) || ...
                    (y1 >   1 && x1 < col && gindex(y1-1, x1+1) ~= hgindex && is_large_area(gindex(y1-1, x1+1)) == 1) || ...
                    (            x1 >   1 && gindex(y1  , x1-1) ~= hgindex && is_large_area(gindex(y1  , x1-1)) == 1) || ...
                    (            x1 < col && gindex(y1  , x1+1) ~= hgindex && is_large_area(gindex(y1  , x1+1)) == 1) || ...
                    (y1 < row && x1 >   1 && gindex(y1+1, x1-1) ~= hgindex && is_large_area(gindex(y1+1, x1-1)) == 1) || ...
                    (y1 < row &&             gindex(y1+1, x1  ) ~= hgindex && is_large_area(gindex(y1+1, x1  )) == 1) || ...
                    (y1 < row && x1 < col && gindex(y1+1, x1+1) ~= hgindex && is_large_area(gindex(y1+1, x1+1)) == 1))
                    above_75_percent_area_block_border_count(loop) = above_75_percent_area_block_border_count(loop) + 1;
                end

                % Count pixels bordering 1 large area
                if is_large_area(hgindex) == 1 && (...
                    (y1 >   1 && x1 >   1 && gindex(y1-1, x1-1) ~= hgindex) || ...
                    (y1 >   1 &&             gindex(y1-1, x1  ) ~= hgindex) || ...
                    (y1 >   1 && x1 < col && gindex(y1-1, x1+1) ~= hgindex) || ...
                    (            x1 >   1 && gindex(y1  , x1-1) ~= hgindex) || ...
                    (            x1 < col && gindex(y1  , x1+1) ~= hgindex) || ...
                    (y1 < row && x1 >   1 && gindex(y1+1, x1-1) ~= hgindex) || ...
                    (y1 < row &&             gindex(y1+1, x1  ) ~= hgindex) || ...
                    (y1 < row && x1 < col && gindex(y1+1, x1+1) ~= hgindex))
                    above_75_percent_area_block_all_border_count(loop) = above_75_percent_area_block_all_border_count(loop) + 1;
                end

                if is_large_area(hgindex) == 1
                    above_75_percent_area_block_pixel_count(loop) = above_75_percent_area_block_pixel_count(loop) + 1;
                end
            end
        end
    end

    % Store total block area, large group block area, borders between 2 large areas in block, border of 1 large area in block
    data{5} = above_75_percent_area_block_count;
    data{6} = above_75_percent_area_block_pixel_count;
    data{7} = above_75_percent_area_block_border_count;
    data{8} = above_75_percent_area_block_all_border_count;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')

    % compute NR parameters
    % 
    % Currently for images without sanding or rough areas, 'contour_average'
    %    should be a good indicator of image quality.
    % However for rough images, please use 'contour_relative_border_score'
    %    'contour_relative_all_border_score' as these scores ignore 
    %    large rough areas computes the border pixel weight of major areas.
    %    These larger areas are
    %    currently defined as the largest areas that make up 75% of the 
    %    total image area.  Currently the score is computed by major area
    %    border pixels over total area.
    feature_data = varargin{1,1};

    % Pixels part of a border on major area over total major areas.(Should be 0 to 1)
    above_75_percent_area_block_pixel_count      = feature_data{6};
    above_75_percent_area_block_border_count     = feature_data{7};
    above_75_percent_area_block_all_border_count = feature_data{8};

    border_total     = 0;
    all_border_total = 0;
    count            = 0;

    % Iterate through blocks and sum border pixels / total area segment pixels
    for index=1:length(above_75_percent_area_block_pixel_count)
        if above_75_percent_area_block_pixel_count(index) > 0
            border_total     = border_total     + above_75_percent_area_block_border_count(index)     / above_75_percent_area_block_pixel_count(index);
            all_border_total = all_border_total + above_75_percent_area_block_all_border_count(index) / above_75_percent_area_block_pixel_count(index);
            count = count + 1;
        end
    end

    % Get average border pixels / total area segment pixels
    data(1) =     border_total / count;
    data(2) = all_border_total / count;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
