function [data] = nrff_fine_detail(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard NRFF function calls.
% 
%  This NRFF measures quality loss associated with a loss of fine detail.
%  This may be caused by too aggressive noise reduction, or image resizing. 
%  Small edges are analyzed by comparison to large edges.
%
%  This algorithms emphasizes calculation speed and simplicity.
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'FineDetail';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')

    data{1} = 'FineDetailWhole'; 
    data{2} = 'SI_5_15_mean'; 
    data{3} = 'SI5_histogram';
    data{4} = 'SI15_histogram';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'S-FineDetail';
    data{2} = 'S-Noise';
    data{3} = 'S-Clipped';
    data{4} = 'S-Texture';   % most datasets, upper triangle, edge energy 
                           % associated with high quality
                           % its4s_dataset has some exceptions where
                           % extreme blockiness yields strong edge energy
                           % but low quality

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
    
    % Filter Y plane with edges of various sizes, then correlate
    extra = 7;
    [si5] = filter_si_hv_adapt(y, 5, extra);
    [si15] = filter_si_hv_adapt(y, 15, extra);
    
    % correlate large & small edges
    tmp = corrcoef(si5, si15);
    data{1} = tmp(1,2);

    % Sort SI15 pixel locations by strength of SI15, lowest to highest
    [~,locn] = sort(si15);
    len = length(locn);

    % Find the 5% of pixels that have the lowest 
    % edge energy areas, based on large edges (Si15). 
    want = locn(floor(1:len * 0.05));

    % calculate the average over those pixels, of SI5 and SI15 
    data{2}(1) = mean(si5(want));
    data{2}(2) = mean(si15(want));

    % calculate simplified histograms, indicating how much of the image has
    % very low or very high amounts of strong edges.
    len = length(si15(:));

    si15V = si15(:);
    data{3}(1) = length( find(si15V < 1) ) / len;
    data{3}(2) = length( find(1 <= si15V & si15V < 2) )/ len;
    data{3}(3) = length( find(2 <= si15V & si15V < 4) )/ len;
    data{3}(4) = length( find(4 <= si15V & si15V < 8) )/ len;
    data{3}(5) = length( find(8 <= si15V & si15V < 16) )/ len;
    data{3}(6) = length( find(16 <= si15V & si15V < 32) )/ len;
    data{3}(7) = length( find(32 <= si15V & si15V < 64) )/ len;
    data{3}(8) = length( find(64 <= si15V & si15V < 128) )/ len;
    data{3}(9) = length( find(128 <= si15V & si15V < 256) )/ len;
    data{3}(10) = length( find(256 <= si15V & si15V < 512) )/ len;
    data{3}(11) = length( find(512 <= si15V ) ) / len;

    % calculate simplified histograms, indicating how much of the image has
    % very low or very high amounts of strong edges.
    len = length(si5(:));

    si5V = si5(:);
    data{4}(1) = length( find(si5V < 1) ) / len;
    data{4}(2) = length( find(1 <= si5V & si5V < 2) )/ len;
    data{4}(3) = length( find(2 <= si5V & si5V < 4) )/ len;
    data{4}(4) = length( find(4 <= si5V & si5V < 8) )/ len;
    data{4}(5) = length( find(8 <= si5V & si5V < 16) )/ len;
    data{4}(6) = length( find(16 <= si5V & si5V < 32) )/ len;
    data{4}(7) = length( find(32 <= si5V & si5V < 64) )/ len;
    data{4}(8) = length( find(64 <= si5V & si5V < 128) )/ len;
    data{4}(9) = length( find(128 <= si5V & si5V < 256) )/ len;
    data{4}(10) = length( find(256 <= si5V & si5V < 512) )/ len;
    data{4}(11) = length( find(512 <= si5V ) ) / len;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
    % compute NR parameters

    % input parameters
    feature_data = varargin{1,1};
    fps = varargin{2};
    image_size = varargin{3};
    
    % Pearson correlation squared, so R-squared
    data(1) = ( nanmean(squeeze(feature_data{1})) )^2;
    
    % Minimum observed value is 0.01 for vqegHDcuts (high quality)
    % maximum observed value is 1.0 for cid2013
    % no rescaling needed. Already in range [0..1] where 0 = high quality
    % and 1 = low quality
    
    % Take the amount of small edge energy, in pixels with lowest 5% of large edges,
    % and normalized by the strength of large edges in this area. 
    % This should indicate camera capture noise.  
    values = feature_data{2};

    tmp = values(:,:,1) ./ max(1, values(:,:,2)); 
    
    % Then normalize that by 20, which is the largest value observed.
    % That 20 value was an outlier from picture of sand.
    data(2) = nanmean(tmp) / 20;

    % Fraction of the image that is completely flat, featureless
    % sqrt improves linearity to MOS
    values = feature_data{3};
    data(3) = sqrt( nanmean(values(:,:,1)) );

    % Small edge energy associated with high quality
    % manual examination indicates need to boost by x2 to be on scale from
    % 0..1.
    % sqrt improves linearity to MOS
    values = feature_data{4};
    data(4) = sqrt( nanmean(values(:,:,8)) * 2 );



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
