function [data] = nrff_panIPS(type, varargin)
% No-Reference Feature Function (NRFF)
%   Calculates the quality of camera pans in images per second (IPS).
%   IPS is the percentage of the image traveled in one second.
%
%   Returns the calculated IPS value associated with the horizontal pan
%   motion and the vertical pan motion. For example given a 1920 by 1080 picture
%   if the image travels all the way across the 1920 pixels it will have a
%   horizontal IPS value of 1.
%
%   Parameter #1, PanSpeed, is the original estimation of pan quality.
%   Parameter #3, PanSpeed2, is an updated estimation of pan quality that
%                 is designed to complement parameter #2, Jiggle.
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % overall name of this group of NR features
    if strcmp(type, 'group')
        data = 'panIPS';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create NR feature names
    elseif strcmp(type, 'feature_names') 

        data{1} = 'VertShift2';
        data{2} = 'HorizShift2';
        data{3} = 'VertBlocks';
        data{4} = 'HoriBlocks';
        data{5} = 'TrustBlocks';



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create NR parameter names
    elseif strcmp(type, 'parameter_names')

        data = {'S-PanSpeed', 'S-Jiggle'};

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % color space
    elseif strcmp(type, 'luma_only')
        data = true;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % calculate with overlapping two frames
    elseif strcmp(type, 'read_mode')
        data = 'ti';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % tell calculate_NRpars to use parallel_mode
    elseif strcmp(type, 'parallelization')
        data = true; 

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif strcmp(type, 'pixels')
        fps = varargin{1};
        y = varargin{2};

        y1 = y(:,:,1);
        y2 = y(:,:,2);

        [~,~,frames] = size(y);
        if frames ~= 2
            error('This feature must be given exactly 2 frames in the "pixels" function call');
        end

        % Calculate alignment using 100 blocks, random subsampling of pixels
        [vertIPS, horizIPS, vert_blocks, horiz_blocks, trust_blocks] = AlignImages(y1, y2, fps);

        data{1} = vertIPS;
        data{2} = horizIPS;
        data{3} = vert_blocks;
        data{4} = horiz_blocks;
        data{5} = trust_blocks;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elseif strcmp(type, 'pars')

        feature_data = varargin{1};
        fps = varargin{2};

        % this is an image, so FPS is undefined. 
        % Return "no motion" and "no jiggle".
        if isnan(fps)
            data(1,1:2) = 0;
            return;
        end

        % rename features with meaningful names
        frame_vert2  = feature_data{1};
        frame_horiz2 = feature_data{2};
        block_vert   = feature_data{3}; % subscripts: (frames, 1, blocks)
        block_horiz  = feature_data{4}; % subscripts: (frames, 1, blocks)
        block_trust  = feature_data{5}; % subscripts: (frames, 1, blocks)

        % Compute jiggle from the updated horizontal & vertical shifts

        % calculating over 0.2 seconds of frames at a time
        % but make sure it is a multiple of 2 and at least 4 frames.
        addF = ceil(fps / 5);   
        addF = max(addF, 4);
        addF = addF + mod(addF,2);
        totalF = size(frame_horiz2,1);
        total = ceil(totalF / addF);

        meanV = zeros(1,total);
        meanH = zeros(1,total);
        meanV2 = zeros(1,total);
        meanH2 = zeros(1,total);

        stdHV = zeros(1,total);

        % for each 0.2 second, compute a different estimate
        for cntS = 1:total
            frame1 = 1 + (cntS-1) * addF;
            frameN = addF + (cntS-1) * addF;
            frameN = min(totalF, frameN);

            % Estimate pan speed using average horizontal and vertical
            % motion. NaN shifts are ignored.

            meanV(cntS) = nanmean(frame_vert2(frame1:frameN));
            meanH(cntS) = nanmean(frame_horiz2(frame1:frameN));

            segV = block_vert(frame1:frameN,:);
            segH = block_horiz(frame1:frameN,:);
            segT = block_trust(frame1:frameN,:);
            tmpV = ones(1,size(segH,2));
            tmpH = ones(1,size(segH,2));
            for cntB = 1:size(segH,2)
                tmp = segT(:,cntB);
                want = tmp < 0.05;
                tmpV(cntB) = nanmean(segV(want,cntB));
                tmpH(cntB) = nanmean(segH(want,cntB));
            end
            meanV2(cntS) = st_statistic('between25%75%', tmpV);
            meanH2(cntS) = st_statistic('between25%75%', tmpH);

            % estimate jiggle based on standard deviation of horizontal and
            % vertical motion. 

            % But ... we need to eliminate the impact of frames digitally repeated 
            % frame rate conversions. Compression can add noise to repeated frames, 
            % which will cause stdHV to be erroneously high (e.g., time history of 
            % [0.1 5 0.2 6 0.1 5 0.1 5 0.2 5 0.1 6]. 

            % Start by eliminating situations where there is too little data.
            % Need 4 frames to get 2 sequential values, combining horizontal
            % and vertical then yields enough values to compute standard deviation. 
            if (frameN - frame1 + 1) < 4
                stdHV(cntS) = nan;
                break;
            end

            % compute std three ways: every frame, every other frame starting
            % on frame 1, and every other frame starting on frame 2.
            % This will only catch 2x frame reductions. It will fail on slower
            % frame speed reductions, and 3-2 pulldown.
            segH2 = frame_horiz2(frame1:2:frameN);
            segH3 = frame_horiz2(frame1+1:2:frameN);

            segV2 = frame_vert2(frame1:2:frameN);
            segV3 = frame_vert2(frame1+1:2:frameN);

            option2 = nanstd([ segH2 - mean(segH2); segV2 - mean(segV2) ]);
            option3 = nanstd([ segH3 - mean(segH3); segV3 - mean(segV3) ]);

            % choose among estimates.
            stdHV(cntS) = max(option2, option3);    

        end

        data(1,2) = st_statistic('below50%', stdHV);

        % Replace undefined parameters with zero (no jiggle)
        if isnan(data(1,2))
            data(1,2) = 0;
        end

        % if the features contains only nan, then there is no motion. 
        if isnan(nanmean(meanH)) || isnan(nanmean(meanV))
            data(1,1) = 0;
        else
            % calculate pan speed as euclidean distance, but weight the horizontal
            % more than the vertical, and use only the 50% slowest of above estimates. 
            temp = sqrt( 2 * st_statistic('below50%', abs(meanH))^2 + ...
                st_statistic('below50%', abs(meanV))^2);
            data(1,1) = sqrt(temp / sqrt(fps));
        end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    else
        error('Mode not recognized. Aborting.');
    end
end




function [vertIPS, horizIPS, iv, ih, itrust] = AlignImages(y1, y2, fps)
% This code efficiently aligns images y1 and y2 (subsequent frames).
% Also requires the frame rate (fps).
%
% Returns the vertical and horizontal shift in pixels (try_row and try_col)
% and also the vertical and horizontal shift in image per second (vertIPS
% and horizIPS). Identical images are ignored, because these can result
% from 3-2 pulldown or frame rate conversions, which perceptually do not
% appear as movement. The remaining portions of the video are used as the
% basis of calculation. Note that for analog systems, these situations can
% produce small differences that will not be detected by this simple test,
% and therefore the overall metric can be "misled" to conclude more jiggle
% than is actually present. 
%
% return value "trust" analyzes the reliability of the shift estimate.

    % compute size of these images. Assume check performed already on y2
    % size being equal to y1 size.
    [row,col] = size(y1);
    
    % figure out how far of a shift we will try to detect. Based on studies
    % of bodycams moving quickly, we expect objects to move up to 
    % the full screen each 1/3 second. 
    max_col_shift = ceil(col * 3 / fps);
    max_row_shift = ceil(row * 3 / fps);
    
    % limit these maximums, for very low frame rate video (e.g., 1 fps)
    max_col_shift = min(max_col_shift, floor(col / 4));
    max_row_shift = min(max_row_shift, floor(row / 4));

    % discarding a border of that size, divide the rest of the image into
    % 100 roughly equal sized blocks.
    [blocks] = divide_100_blocks(row, col, max_row_shift, max_col_shift);

    % If this is an image, fps == 0. Handle this special case.
    if isnan(fps)
        vertIPS = 0;
        horizIPS = 0;
        iv = zeros(1,length(blocks));
        ih = zeros(1,length(blocks));
        itrust = zeros(1,length(blocks));
        return;
    end

    % new algorithm to compute shift of each block 
    [ihpixel, ivpixel, itrust] = spatial_registration_block(y1, y2, blocks, max_col_shift, max_row_shift);

    % scale for image per second
    iv = ivpixel .* fps ./ row;
    ih = ihpixel .* fps ./ col;
    
    % Take the median value of the block estimates.
    vertIPS = nanmedian(iv);
    horizIPS = nanmedian(ih);

end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [h_shift, v_shift, trust_blocks] = spatial_registration_block(y1, y2, blocks, max_col_shift, max_row_shift)
% calculate the horizontal shift (h_shift) and vertical shift (v_shift)
% estimate for approximately 100 blocks (blocks) of two subsequent images 
% (y1 and y2). The maximum shift searched is max_col_shift horizontally and
% max_row_shift vertically.
%
% The returned shift estimates can be nan. This occurs if y1 and y2 are
% digitally identical, or for regions where there is too little texture.
% 
% returned value "trust" is a fraction that indicates reliability of the
% shift, based on how much smaller the figure of merit is for the best
% shift examined, compared to the figure of merit for the worst shift
% examined.

    h_shift = zeros(1, length(blocks));
    v_shift = zeros(1, length(blocks));
    trust_blocks = zeros(1, length(blocks));
    
    % Compute spatial registration for each block of one image.
    for cntB = 1:length(blocks)
        % random search.
        best_col = 0;
        best_row = 0;
        best_value = inf;
        worst_value = -inf;

        values = zeros(2*max_col_shift+1,2*max_row_shift+1);
        values(:,:) = NaN;

        % choose 0.2% of pixels at random from this block in image y1. 
        % Keep at least 20 pixels, to ensure robust calculation
        % this approx the 0.2% of pixels expected in a block from 
        % HDTV (1920 x 1080) frames.
        list = randperm(blocks(cntB).pixels);
        keep_num = max(20, round(length(list)/500));
        list = list(1:keep_num); 

        % extract these 0.2% pixels from y1
        this_block = y1(blocks(cntB).top:blocks(cntB).bottom,blocks(cntB).left:blocks(cntB).right);        
        y1_pixels = this_block(list);
        
        % if there is too little spread of pixel values, then don't use
        % this block. Still video when compressed is observed to have
        % std(y) values around 1.1, The default threshold (5) is chosen to
        % be generously above that.
        if std(y1_pixels) < 5
            v_shift(cntB) = nan;
            h_shift(cntB) = nan;
            trust_blocks(cntB) = 0;
            continue;
        end
        

        % try to find optimal alignment in 500 tries.
        random_tries = 500;
        loop = 1;
        while loop <= random_tries

            % Always start with (0,0) shift, to make sure this likely
            % alignment is checked.
            if loop == 1
                try_col = 0;
                try_row = 0;

            % for the first 20% of tries, use a flat distribution
            % to randomly search over all possibilities.
            elseif loop < random_tries / 5
                try_col = round( -max_col_shift + (2 * max_col_shift + 2) * rand );
                try_row =  round( -max_row_shift + (2 * max_col_shift + 2) * rand );
                
            % Then, weight more near best result found so far.  
            else
                try_col = best_col + round( 2 * randn );
                try_row = best_row + round( 2 * randn );
            end

            % If this point is out of the legal range, choose again.
            if abs(try_col) > max_col_shift || abs(try_row) > max_row_shift 
                continue;
            end
            
            % check whether this shift has been computed already.
            if ~isnan( values(try_col + max_col_shift + 1, try_row + max_row_shift + 1) )
                loop = loop + 1;
                continue;
            end

            % extract the shifted 0.2% pixels from y2
            this_block = y2(try_row+(blocks(cntB).top:blocks(cntB).bottom),...
                try_col+(blocks(cntB).left:blocks(cntB).right));  
            y2_pixels = this_block(list);

            % compute the standard deviation of the difference between
            % pixel sets. This is the figure of merit for finding optimal
            % shift.
            curr_value = std( y1_pixels - y2_pixels );
            values(try_col + max_col_shift + 1, try_row + max_row_shift + 1) = curr_value;

            % Keep track of the best and worst shift found.
            if curr_value < best_value
                best_col = try_col;
                best_row = try_row;
                best_value = curr_value;
            elseif curr_value > worst_value
                worst_value = curr_value;
            end

            loop = loop + 1;
        end

        v_shift(cntB) = best_row;
        h_shift(cntB) = best_col;
        
        % compute the trustworthiness of this shift, based on the figure of
        % merit for the best and worst shifts found. Avoid small divisors
        % exploding this trust estimate.
        trust_blocks(cntB) = best_value / max(1, worst_value); 
    
    end
    
end



