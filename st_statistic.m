function [data,names] = st_statistic(request, raw_data, option)
% ST_STATISTIC
%  Compute the requested spatial-temporal (ST) collapsing function.
% SYNTAX
%  [data, names] = st_statistic(request, raw_data)
%  [data, names] = st_statistic(request, raw_data, option)
% DESCRIPTION
%  Compute the requested spatial or temporal collapsing function, using
%  ALL data in the array or matrix, 'raw_data', and return the
%  results in 'data'. Return variable 'names" will have the name of the
%  function calculated (typically the same as 'request').
%
%  The available precentile functions are as follows. The meanings are as 
%  defined in "Video Quality Measurement Techniques" NTIA Technical Report 02-392.
%   'mean', 'std', 'rms', 'min', 'max', 'range' 'abs_mean'
%   '10%', '25%', '50%', '75%', '90%', 
%   'above99%', 'above98%', 'above95%', 'above90%', 'above75%', 
%   'above50%', 'above25%', 'above10%',
%           [ The meaning of 'aboveX%' is to average all values above the Xth percentile] 
%   'above90%tail', 'above95%tail', 'above98%tail', 'above99%tail', 
%           [ The meaning of 'aboveX%tail' is to average all values above 
%             the Xth percentile, then subtract the Xth percentile] 
%   'below1%', 'below2%', 'below5%', 'below10%', 'below25%', 'below50%', 
%   'below75%' 'below90%' 
%   'below1%tail, 'below2%tail', 'below5%tail', 'below10%tail', 'below50%tail'
%           [ These are as the 'above' but computed below the selected percentile]
%   'between25%50%', 'between25%75%', 'between10%90%'
%           [ The meanings of 'betweenX%Y%' is to averge values beteen the Xth and Yth percentile ]
%   'minkowski(P,R)'
%           [ minkowski = mean(abs(raw_data).^P).^(1/R) ]
%           Where 'P' and 'R' are replaced with the actual values to be
%           used.  For example, 'minkowski(1.8,2.8)' or 'minkowski(6,7)'
%
%  Each of these requests calculates a variety of statistics. 'option' must
%  be 'SpatialTemporal'.  The identities and order of the sub-requests will be
%  returned in 'names'.
%   'various' 
%       [ 'mean', 'std', 'rms', 'min', 'max', 'range', '10%', '25%', '50%', '75%', '90%', ...
%         'between25%50%', 'between25%75%', 'between10%90%' 'above90%' 'below10%' ] 
%   'varioushigh'  
%       [ 'mean', 'std', 'max', '75%', '90%', 'above99%', 'above98%', 'above95%', 'above90%', 'above75%' ] 
%   'variouslow' 
%       [ 'mean', 'std', 'min', '25%', '10%', 'below1%', 'below2%', 'below5%', 'below10%', 'below25%', 'below50%' ] 
%
% The following values for 'option' input parameters may be specified.
%
%   'SpatialTemporal', or
%   'ST',   Apply the requested function simultaneously to all dimensions,
%           Spatial and Temporal (ST). Thus, convert all of the data into a 
%           1D array and apply the colllapsing function to that 1D array. 
%           This is the default behavior.
%   'Spatial', Assume that 'raw_data' is formatted as (t,x,y) where 't' is
%           time; 'x' and 'y' delineate any spatial indexes. Apply the 
%           statistic specified in 'request' separately to each value of 't'.
%
% WARNING: 'nan' and 'inf' values will be discarded. 

collapse_3d = 1;

if exist('option','var')
    if strcmpi(option,'st') || strcmpi(option,'spatialtemporal')
        collapse_3d = 1;
    elseif strcmpi(option,'spatial')
        collapse_3d = 0;
    else
        error('Function st_statistic, "option" input argument not recognized');
    end
end


% if wanting to collapse a 3D structure all at once, reshape into an array.
[t,x,y] = size(raw_data);
if collapse_3d
    raw_data = reshape(raw_data, t*x*y,1);
else
    % Recurse, calculating for each time offset. Then return.
    data = nan(t,1);
    for cnt=1:t
        data(cnt) = st_statistic(request, raw_data(cnt,:,:));
    end
    return;
end


%------------------------------------------------------------------------
% handle requests for multiple statistics
if strcmpi(request,'various') || strcmpi(request,'varioushigh') || strcmpi(request,'variouslow')
    if collapse_3d == 0
        error('Request for various statistics cannot be accomodated with "Spatial" option');
    end

    % specify list of statistics to be calculated
    if strcmpi(request,'various') 
        names = { 'mean', 'std', 'rms', 'min', 'max', 'range', '10%', '25%', '50%', '75%', '90%', ...
                  'between25%50%', 'between25%75%', 'between10%90%', 'above90%', 'below10%'};
    elseif strcmpi(request,'varioushigh') 
        names = {'mean', 'std', 'max', '75%', '90%', 'above99%', 'above98%', 'above95%', 'above90%', 'above75%' };
    elseif strcmpi(request,'variouslow')
        names = {'mean', 'std', 'min', '25%', '10%', 'below1%', 'below2%', 'below5%', 'below10%', 'below25%', 'below50%' };
    end
    
    % recursively calculate 
    data = nan(length(names),1);
    for cnt=1:length(names)
        data(cnt) = st_statistic(names{cnt}, raw_data);
    end
    
    return;
end



%------------------------------------------------------------------------
% handle request for single statistic
% 'names' now is the same as input variable 'request'
names = request;

% discard nan values and inf values
raw_data = raw_data(~isnan(raw_data));
if isempty(raw_data)
    data = nan;
    return;
end
raw_data = raw_data(~isinf(raw_data));
if isempty(raw_data)
    data = inf;
    return;
end



% Apply requested function.
above = 0;
below = 0;
tail = 0;

[t,~,~] = size(raw_data);
if t == 1 
    % Special case.  ST-collapse over a singleton dimension.  This is
    % always either the same as the input or zero.  
    if strcmp(request,'std') || ~isempty(findstr(request,'tail'))
        data = 0 * raw_data;
    else
        data = raw_data;
    end
    
% handle the usual cases.
elseif strcmp(request,'mean')
    data = mean(raw_data);
elseif strcmp(request,'abs_mean')
    data = mean(abs(raw_data));
elseif strcmp(request,'std')
    data = std(raw_data);
elseif strcmp(request,'rms')
    data = sqrt(mean(raw_data.^2));
elseif strcmp(request,'min')
    data = min(raw_data);
elseif strcmp(request,'max')
    data = max(raw_data);
elseif strcmp(request,'range')
    data = max(raw_data)-min(raw_data);
elseif strncmp(request, 'minkowski(', 10)
    [mink, n] = sscanf(request(11:length(request)), '%f,%f');
    if n ~= 2
        error('Cannot parse minkowski P and R values in string "%s"', request(10:length(request)));
    end
    data = mean(abs(raw_data).^mink(1)).^(1.0/mink(2));
elseif strcmp(request,'between25%50%') || strcmp(request,'between25%75%') || strcmp(request,'between10%90%')
    if strcmp(request,'between25%50%') 
        percentile1 = 0.25;
        percentile2 = 0.50;
    elseif strcmp(request,'between25%75%') 
        percentile1 = 0.25;
        percentile2 = 0.75;
    else % strcmp(request,'between10%90%')
        percentile1 = 0.10;
        percentile2 = 0.90;
    end

	% if 1D but wrong direction vector, transpose it.
    [r,~] = size(raw_data);
	if ndims(raw_data) == 2 && r == 1
        raw_data = raw_data';
    end
	
	% compute percentile functions
	[rows,~] = size(raw_data);
	
	want1 = 1 + round((rows-1) * percentile1);
	want2 = 1 + round((rows-1) * percentile2);
	
	raw_data_sorted = sort(raw_data, 1);
    data = mean(raw_data_sorted(want1:want2,:,:,:),1);
else
    if strcmp(request,'10%')
        percentile = 0.10;
	elseif strcmp(request,'25%')
        percentile = 0.25;
	elseif strcmp(request,'50%')
        percentile = 0.50;
	elseif strcmp(request,'75%')
        percentile = 0.75;
	elseif strcmp(request,'90%')
        percentile = 0.90;
	elseif strcmp(request,'above99%')
        percentile = 0.99;
        above = 1;
	elseif strcmp(request,'above95%')
        percentile = 0.95;
        above = 1;
	elseif strcmp(request,'above98%')
        percentile = 0.98;
        above = 1;
	elseif strcmp(request,'above90%')
        percentile = 0.90;
        above = 1;
	elseif strcmp(request,'above75%')
        percentile = 0.75;
        above = 1;
	elseif strcmp(request,'above50%')
        percentile = 0.50;
        above = 1;
	elseif strcmp(request,'above25%')
        percentile = 0.25;
        above = 1;
	elseif strcmp(request,'above10%')
        percentile = 0.10;
        above = 1;
	elseif strcmp(request,'below1%')
        percentile = 0.01;
        below = 1;
	elseif strcmp(request,'below2%')
        percentile = 0.02;
        below = 1;
	elseif strcmp(request,'below5%')
        percentile = 0.05;
        below = 1;
	elseif strcmp(request,'below10%')
        percentile = 0.10;
        below = 1;
	elseif strcmp(request,'below25%')
        percentile = 0.25;
        below = 1;
	elseif strcmp(request,'below50%')
        percentile = 0.50;
        below = 1;
	elseif strcmp(request,'below75%')
        percentile = 0.75;
        below = 1;
	elseif strcmp(request,'below90%')
        percentile = 0.90;
        below = 1;
	elseif strcmp(request,'above95%tail')
        percentile = 0.95;
        above = 1;
        tail = 1;
	elseif strcmp(request,'below5%tail')
        percentile = 0.05;
        below = 1;
        tail = 1;
	elseif strcmp(request,'below50%tail')
        percentile = 0.50;
        below = 1;
        tail = 1;
	elseif strcmp(request,'below2%tail')
        percentile = 0.02;
        below = 1;
        tail = 1;
	elseif strcmp(request,'above98%tail')
        percentile = 0.98;
        above = 1;
        tail = 1;
	elseif strcmp(request,'above99%tail')
        percentile = 0.99;
        above = 1;
        tail = 1;
	elseif strcmp(request,'below1%tail')
        percentile = 0.01;
        below = 1;
        tail = 1;
	elseif strcmp(request,'above90%tail')
        percentile = 0.90;
        above = 1;
        tail = 1;
	elseif strcmp(request,'below10%tail')
        percentile = 0.10;
        below = 1;
        tail = 1;
	else
        error('ERROR: percentile function "%s" not recognized by function compute_percentile', request);
    end
	
	% compute percentile functions
	[rows,~] = size(raw_data);
	
	want = 1 + round((rows-1) * percentile);
	%fprintf('r=%d, c=%d, percentile %f, want=%d\n', rows, cols, percentile, want);
	
	raw_data_sorted = sort(raw_data, 1);
	if ~below && ~above && ~tail
        data = raw_data_sorted(want,:,:,:);
	elseif above && ~tail
        data = mean(raw_data_sorted(want:rows,:,:,:),1);
	elseif below && ~tail
        data = mean(raw_data_sorted(1:want,:,:,:),1);
	elseif above && tail
        if want == rows
            % special case, can't do tail.
            data = raw_data_sorted(want,:,:,:) * 0;
        else
            data = mean(raw_data_sorted(want:rows,:,:,:),1) - raw_data_sorted(want,:,:,:);
        end
	elseif below && tail
        if want == 1
            % special case, can't do tail.
            data = raw_data_sorted(want,:,:,:) * 0;
        else
            data = raw_data_sorted(want,:,:,:) - mean(raw_data_sorted(1:want,:,:,:),1);
        end
    end
end	
	
% get rid of extra dimension.
[a,b,c,d] = size(data);
data = reshape(data,b,c,d);