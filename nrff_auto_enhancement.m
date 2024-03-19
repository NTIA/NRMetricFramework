function [data] = nrff_auto_enhancement(mode, varargin)
% No-Reference Feature Function (NRFF)
%   Implement standard function calls to calculate image auto-enhancement features
%   That is, features associated with autocontrast, white level, and black
%   level. 
% 
% PARAMETERS
%   par 1, white level, measures whether the white level is too low 
%                       i.e., the image is too dark
%   par 2, black level, measures whether the black level is too high  
%                       i.e., the image is too light or fully white
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'auto_enhancement';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names') 

    data{1} = 'white level';
    
    data{2} = 'black level';

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names
elseif strcmp(mode, 'parameter_names')

    data{1} = 'S-WhiteLevel'; % 98% white level, clipped at 150 maximum, ignore black border.
    
    data{2} = 'S-BlackLevel'; % black level is too high; image whitewashed
    
    data{3} = 'WhiteClipping'; % Fraction of image that is clipped white
    
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

    % compute features.
    % Put all into the same data array, associated with the same feature name.
    
    
    % discard black border. Call Y <= 32 "black"
    col_max = max(y);
    row_max = max(y,[],2);
    
    % Warning: make sure this special case (all black image) returns the
    % same number of features as the rest of the function, or this function
    % will; fail.
    if max(col_max) <= 32
        % whole image is black; feature invalid
        data{1}(1) = nan;
        data{1}(2) = 0;
        data{1}(3) = nan;
    else
    
        min_col = 1;
        while col_max(min_col) <= 32
            min_col = min_col + 1;
        end
        max_col = length(col_max);
        while col_max(min_col) <= 32
            max_col = max_col - 1;
        end
        min_row = 1;
        while row_max(min_row) <= 32
            min_row = min_row + 1;
        end
        max_row = length(row_max);
        while row_max(min_row) <= 32
            max_row = max_row - 1;
        end

        y_nbe = y(min_row:max_row, min_col:max_col);

        % compute features.
        % Put all into the same data array, associated with the same feature name.
        [row,col] = size(y_nbe);
        pixels = row*col;
        y_vector = sort(reshape(y_nbe,row*col,1));

        % 98th percentile luma, indicating white level
        offset_98 = floor(pixels*0.98); 
        data{1}(1) = y_vector( offset_98 );

        % Number of pixels clipped at white (235 or above)
        % use "greater than 234" due to coding/decoding noise 
        data{1}(2) = length(find(y_vector > 234)) / (row*col);

        % Calculate how sharp edges are, adjacent to clipped white areas. 
        % Again, use > 234 instead of 235, due to rounding by codecs
        % Only look horizontally (for computational efficiency) for three
        % pure white pixels next to two darker pixels.
        extra = 2;

        yn2 = y(extra+1:row-extra, extra+1-2:col-extra-2);
        yn1 = y(extra+1:row-extra, extra+1-1:col-extra-1);
        y0 = y(extra+1:row-extra, extra+1:col-extra);
        y1 = y(extra+1:row-extra, extra+1+1:col-extra+1);
        y2 = y(extra+1:row-extra, extra+1+2:col-extra+2);
 
        want = [ find(yn2 > 234 & yn1 > 234 & y0 > 234 & y1 <= 233 & y2 <= 233 ); find(y2 > 234 & y1 > 234 & y0 > 234 & yn1 <= 233 & yn2 <= 233 )];

        % Compute the average. Ignore the middle point (y0) which is by
        % definition approximately 235. Clip this at zero, to ignore
        % excursions above 235 (e.g., some videos clip white at 255) 
        data{1}(3) = 235 - mean(y1(want) + y2(want) + yn1(want) + yn2(want))/4;
        data{1}(3) = max(0, data{1}(3));

    end
    
    % take mean and standard deviation of the luma image
    data{2}(1) = nanmean(y(:));
    data{2}(2) = nanstd(y(:));
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')


    % compute NR parameters, using mean over time
    % use nanmean, for safety

    feature_data = varargin{1,1};

    data(1) = nanmean(squeeze(feature_data{1}(:,1,1)));
    if isnan(data(1))
        data(1) = 235;
    end

    % clip white level at 150 maximum
    data(1) = min(data(1), 150);

    % Scale from native range to [0..1], where 0 = high quality and 1 = low quality.
    % Lowest observed value, low quality, 16.86 for CID2013. We round down to 10.
    % Highest observed value, high quality, 150 for most media
    % So subtract 10 then divide by 140. Invert range.
    data(1) = 1 - (data(1) - 10) / 140;
    
    % Estimate whether the black level is too high, based on the standard
    % deviation of the luma image. This will also detect too dark images,
    % as per data(1), so we must invalidate this parameter when 
    % the mean image value is below mid level grey (128). In that case,
    % clip to 20, which was determined experimentally using the CCRIQ
    % dataset. Above 20, this parameter spans the full range of MOS.
    % the 128 threshold was also determined experimentally using the CCRIQ
    % dataset, based on maximum accuracy when complimenting metric Sawatch
    % version 1.0.    
    if feature_data{2}(1) < 128
        data(2) = 20;
    else
        data(2) = min(20, feature_data{2}(2));
    end
    
    % rescale to range [0..1] where 0 is no impairment
    data(2) = (20 - data(2)) / 20;

    % Compute the fraction of clipped white pixels
    % Ignore (set to zero) if the adjacent edge energy is too strong,
    % because these are probably computer graphics with a background set to
    % white. "Too strong" is set to 15, based on observations from the
    % training datasets. 
    white_clip_frac = nanmean(squeeze(feature_data{1}(:,1,2)));
    edge = nanmean(squeeze(feature_data{1}(:,:,3)));
    if isnan(edge) % no solid edges, leave as-is
        data(3) = white_clip_frac;
    else
        data(3) = 0;
    end
 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
