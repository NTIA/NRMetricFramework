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

    data{1} = 'white level'; % 98% white level, clipped at 150 maximum, ignore black border.
    
    data{2} = 'black level'; % black level is too high; image whitewashed
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
elseif strcmp(mode, 'luma_only')
    data = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
elseif strcmp(mode, 'read_mode')
    data = 'si';

    
    
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
        data{1} = nan;
        data{2} = max(col_max);
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


        offset_98 = floor(pixels*0.98); 
        data{1} = y_vector( offset_98 );
    end
    
    % take mean and standard deviation of the luma image
    data{2}(1) = nanmean(y(:));
    data{2}(2) = nanstd(y(:));
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')


    % compute NR parameters, using mean over time
    % use nanmean, for safety

    feature_data = varargin{1,1};

    data(1) = nanmean(squeeze(feature_data{1}));
    if isnan(data(1))
        data(1) = 235;
    end

    % clip white level at 150 maximum
    data(1) = min(data(1), 150);

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
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
