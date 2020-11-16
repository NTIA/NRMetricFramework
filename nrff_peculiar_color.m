function [data] = nrff_peculiar_color(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard function calls to calculate features.
%
%  Goal is to estimate visible camera noise, indicated by random differences
%  between the Cb and Cr color planes that are not supported by color theory.
%  This parameter also detects other peculiar differences between the Cb
%  and Cr color planes, including image enhancement that breaks the
%  expected relationship between Cb and Cr; color impairments around the
%  edges of objects. 
%
%  This function also calculates two parameters that analyze on the spread
%  of color information, indicative of whether the media has highly
%  saturated color or little color (pallid). The super saturation parameter
%  is informative but does not track MOS.
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'PeculiarColor';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')

    data{1} = 'Cb-Cr-SI-Corr';
    data{2} = 'Cb-Std';
    data{3} = 'Cr-Std';
    data{4} = 'Super_Sat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'ColorNoise';
    data{2} = 'SuperSaturated';
    data{3} = 'Pallid';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
elseif strcmp(mode, 'luma_only')
    data = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
elseif strcmp(mode, 'read_mode')
    data = 'si';

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pixels')
    fps = varargin{1};
    y = varargin{2};
    cb = varargin{3};
    cr = varargin{4};

    [~,~,frames] = size(y);
    if frames ~= 1
        error('This feature must be given exactly 1 frame in the tslice function call');
    end
    
    % edge filter SI 11
    % this filter size was chosen by examining performance on the CCRIQ
    % dataset. 
    filter_size = 11;
    filter_extra = 5;
    cb_si = filter_si_hv_adapt(cb, filter_size, filter_extra);
    cr_si = filter_si_hv_adapt(cr, filter_size, filter_extra);

    % shrink other image planes as per the filter
    [row,col] = size(cb_si);
    y = y(filter_extra+1:row+filter_extra, filter_extra+1:col+filter_extra);
    cb = cb(filter_extra+1:row+filter_extra, filter_extra+1:col+filter_extra);
    cr = cr(filter_extra+1:row+filter_extra, filter_extra+1:col+filter_extra);

    % Now, divide into 100 blocks
    blocks = divide_100_blocks(row, col, 0);
    
    num_blocks = length(blocks);
    data{1} = zeros(num_blocks,1); 
    data{2} = zeros(num_blocks,1); 
    data{3} = zeros(num_blocks,1); 
    data{4} = zeros(num_blocks,1); 

    for loop = 1:num_blocks
        curr_cb_si = cb_si(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);
        curr_cr_si = cr_si(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);
        curr_cb = cb(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);
        curr_cr = cr(blocks(loop).top:blocks(loop).bottom,blocks(loop).left:blocks(loop).right);

        data{1}(loop) = corr( curr_cb_si(:), curr_cr_si(:)); 
        data{2}(loop) = std(curr_cb(:)); 
        data{3}(loop) = std(curr_cr(:)); 
        data{4}(loop) = length(find(curr_cb(:) > 64 | curr_cr(:) > 64)) / length(curr_cb(:));
    end
    
   
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
    % compute NR parameters

    feature_data = varargin{1,1};
    fps = varargin{2};
    image_size = varargin{3};

    % pull values of interest into local variables
    noise =   feature_data{1};
    cb_std =  feature_data{2};
    cr_std =  feature_data{3};
    sat =     feature_data{4};
    
    % thresh by low maximum cb / cr std 
    if max(cb_std(:)) < 3 || max(cr_std(:)) < 3
        % probably black / white / grey, where the color differences are
        % simply not visible.
        % Also, there is so little color, that the Pearson correlation
        % is overly impacted by sampling errors 
        data(1) = nan;
    else
        data(1) = st_statistic( 'above90%', noise, 'ST');
        
        % clip at 0.9 correlation maximum
        % based on overall analysis of multiple datasets, above this value the
        % parameter becomes unstable (i.e., positive trend for some datasets,
        % negative trend for other datasets).
        data(1) = min(data(1), 0.90);
    end

    
    data(2) = mean(sat(:));
    
    % change below for its4s2, which has multiple frames in time!!!
    want = find(cb_std(:) < 3 | cr_std(:) < 3);
    data(3) = length(want) / length(cb_std(:));



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
