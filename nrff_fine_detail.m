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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'S-FineDetail';
    

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
    

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
