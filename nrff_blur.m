function [data] = nrff_blur(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard function calls to calculate features that estimate
%  the sharpness or blurriness of an image. These algorithms emphasize
%  calculation speed and simplicity.
%
%  Two basic ideas are implemented. The first is based on the unsharp
%  filter. 
% 
%  The second is based on the Laplacian filter, as proposed by the 
%  VQEG Image Quality Evaluation Tool (VIQET, https://github.com/VIQET).
%  NR parameter 'viqet-sharpness' is a modified extension of the VIQET
%  sharpness3 parameter.
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'blur';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')

    data{1} = 'Y_unsharp_above95%';
    data{2} = 'Y_unsharp_range';
    data{3} = 'laplacian-above90%';
    data{4} = 'sobel-std';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'S-Blur';
    data{2} = 'viqet-sharpness';
    

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

    [row,col,frames] = size(y);
    if frames ~= 1
        error('This feature must be given exactly 1 frame in the tslice function call');
    end
    
    % This filter code is inspired by MATLAB 2019A function imsharpen.m
    % Input argument "amount" was removed as unnecessary. Default radius
    % value is taken from imsharpen.m
    radius = 1;
    
    % Gaussian blurring filter
    filtRadius = ceil(radius*2); % 2 Standard deviations include >95% of the area. 
    filtSize = 2*filtRadius + 1;
    gaussFilt = fspecial('gaussian',[filtSize filtSize],radius);

    % High-pass filter (1 in middle, 0 otherwise) added to above filter
    sharpFilt = -gaussFilt;
    sharpFilt(filtRadius+1,filtRadius+1) = sharpFilt(filtRadius+1,filtRadius+1) + 1;

    % Calculate the delta that would be added to pixels as a result of the
    % unsharp filter. Take absolute value, to treat increases and decreases
    % identically. 
    unsharp_diff1 = abs( imfilter(y,sharpFilt,'replicate','conv') );

    % divide the image into approximately 100 blocks. Number of blocks will
    % be the same for each frame of a video. 
    [blocks] = divide_100_blocks(row, col, 0);

    % Compute feature for each block in two ways: above95% and std
    % both will emphasize the larger values, aka sharp edges
    %
    % Divide by the range of filtered values in the block, so the
    % computation yields similar results for black/white edges and
    % grey/white edges. This feature measures the sharpness of the edge,
    % not the magnitude of the edge. 
    for loop = 1:length(blocks)
        this_block = unsharp_diff1(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);

        range = max(max(this_block)) - min(min(this_block));
        
        magnitude = st_statistic('above95%', this_block, 'spatialtemporal');
        data{1}(loop) = magnitude;
      
        data{2}(loop) = range;
    end    
    
    % Now calculate sharpness / blurriness with a modified version of the
    % VIQET sharpness3 parameter.

    % scale values by resolution, to match 1920 * 1080 HD
    % for example, 4K is roughly 2x resolution
    [row,col] = size(y);
    if row < col
        scale_factor = row / 1080;
    else
        scale_factor = col / 1080;
    end
    
    % Laplacian filter the image. If resolution is 4K, sub-sample.
    filt = [-1 -1 -1; -1 8 -1; -1 -1 -1];
    if scale_factor > 1
        % 4K or larger ; reduce to HD resolution
        if mod(row,2) || mod(col,2)
            % odd sized image. make it a power of 2.
            row = floor(row/2)*2;
            col = floor(col/2)*2;
            y2 = y(1:row,1:col);
            y=imresize(y2/256, 0.5)*256;        
        else
            y=imresize(y/256, 0.5)*256;        
        end
    end
    laplacian = abs(conv2(y,filt));
    [rowL,colL] = size(laplacian);
    laplacian = laplacian(2:rowL-1,2:colL-1);
    [rowL,colL] = size(laplacian);
    
    [row,col] = size(y);
    laplacian(1,:) = 0;
    laplacian(row,:) = 0;
    laplacian(:,1) = 0;
    laplacian(:,col) = 0;
    
    sobel = filter_sobel(y);

    if row ~= rowL || col ~= colL
        error('error, these images should be the same size; fix bug before proceeding');
    end
    
    data{3} = st_statistic('above99%', laplacian);
    data{4} = st_statistic('std', sobel);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
    % compute NR parameters
    % 
    % Option 1 for spatial-temporal collapsing is above90%.
    % This will combine data for all frames in time, and all blocks
    % spatially. Should yield robust response to fades. 
    % 
    % Option 2 for spatial-temporal collapsing is max or above90%
    % spatially, then mean temporally.
    % This will combine data each frame, then typical response temporally.
    % This will penalize images that are fully blurred.

    feature_data = varargin{1,1};
    fps = varargin{2};
    image_size = varargin{3};

    data(1) = st_statistic('above90%',feature_data{1} ./ sqrt(max(8, feature_data{2})));

    % 4K is roughly 2x resolution
    % scale 4K and larger resolutions to match 1920 * 1080 HD
    % don't scale smaller resolutions: those indicate perceptible
    % differences
    row = image_size(1);
    col = image_size(2);
    if row < col
        scale_factor = row / 1080;
    else
        scale_factor = col / 1080;
    end
    scale_factor = max(scale_factor,1);
    
    data(1) = data(1) * scale_factor;
    
    % correct non-linearities
    data(1) = sqrt(data(1));
    
    % Scale from native range to [0..1], where 0 = sharp and 1 = maximum blur.
    % cid2013_IS_VI_C01_D14 is totally black, yielding a value of zero. 
    % Ignoring that flat image, the minimum is 0.55.
    % The maximum currently observed is 3.16 from the CCRIQ dataset.
    % So, we will subtract 0.5 and divide by 2.75 (3.16 - 0.5, rounded up). 
    % Then we will clip at zero (set values below zero to zero)
    
    data(1) = 1 - max( 0, ( data(1) - 0.5) / 2.75);
    
    % VIQET sharpness. Scale laplacian edge strength by the spread of sobel
    % values. Regions with soft edges are expected to be more blurry.
    data(2) = nanmean(squeeze(feature_data{3})) ./ sqrt( max(1, nanmean(feature_data{4})));
    
    data(2) = sqrt( max(1, data(2)) );

    % Scale from native range to [0..1], where 0 = sharp and 1 = maximum blur.
    % The minimum observed is 1.0 from CID2013 (probably the same black
    % image) and the maximum currently observed is 10.37 from the
    % vqegHDcuts dataset. We will subtract 1 and divide by 9.5 (rounding
    % up). However, everything above about 0.8 is outliers. 
    
    data(2) = 1 - ( data(2) - 1) / 9.5;
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
