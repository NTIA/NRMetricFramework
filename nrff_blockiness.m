function [data] = nrff_blockiness(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard function calls to calculate features that estimate
%  the blockiness
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'blockiness';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')

    data{1} = 'HV5-blocks-mask';
    data{2} = 'HVB5-blocks';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'S-Blockiness';
    

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

    [~,~,frames] = size(y);
    if frames ~= 1
        error('This feature must be given exactly 1 frame in the tslice function call');
    end
    
    % trust all edges, no matter the angle
    % only want H and V that are extremely close to vertical or horizontal
    rmin = 0;
    theta = 0.01;
    
    fsize = 5; % 5x5 filter
    extra = 2; % cut off edges, invalid from filter
    [~, hv5, hvb5] = filter_si_hv_adapt( y, fsize, extra, rmin, theta);
    
    % Omit HV5 values right next to HVB5 values, because there is too high
    % a chance these are flukes. SI is split between HV and HVB, so we can
    % ignore the center.
    mask = [1 1 1; 1 0 1; 1 1 1];
    hvb_near = ordfilt2(hvb5, 8, mask);
    hv5m = hv5;
    hv5m( hvb_near > 0 ) = 0;

    % divide the image into approximately 100 blocks. Number of blocks will
    % be the same for each frame of a video. Record average value for each
    % plane: filtered HV and HVB (diagonal)
    [row, col] = size(hv5);
    [blocks] = divide_100_blocks(row, col, 0);

    for loop = 1:length(blocks)
        hvm_block = hv5m(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);
        hvb_block = hvb5(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);

        data{1}(loop) = mean(hvm_block(:));      
        data{2}(loop) = mean(hvb_block(:));
    end   

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
    % compute NR parameters
    
    % compute how much stronger the HV edges are, compared to the diagonal
    % edges (HVB), for each block

    % Recall that the SI and HV filter have a 4x multiplier. Thus, an edge
    % strength that measures at 4 is really 1 pixel level difference, which
    % is down in the noise. The 8 threshold below ensures that we don't
    % increase small pixel differences (2 levels or less).
    
    % compute average over each image separately, considering only the
    % areas where this parameter is lowest. This is the worst case, where
    % up to half of the image intentionally contains perfectly vertical 
    % or perfectly horizontal lines (e.g., banner overlaid on a news feed,
    % faux picture frame at the edge of the screen, picture in picture)  
    
    feature_data = varargin{1,1};
    fps = varargin{2};
    image_size = varargin{3};

    [frames, ~, ~] = size(feature_data{1});
    hold1 = zeros(1,frames);
    for cntF = 1:frames
        hvm = feature_data{1}(cntF,1,:);
        hvb = feature_data{2}(cntF,1,:);
        hold1(cntF) =  st_statistic('below50%', hvm(:) ./ max(8, hvb(:)));
    end
    
    data(1) = mean(hold1); 
    
    % Scale from native range to [0..1], where 0 = sharp and 1 = maximum blur.
    % minimum value is zero (0), meaning high quality
    % maximum observed value is 0.21 for AGH/NTIA/Dolby dataset
    % round this up for scaling, and invert. Thus, multiply by 4.5 instead
    % of dividing by 0.2222 repeating.
    data(1) = data(1) * 4.5;

   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
