function [y, cb, cr] = read_media (mode, nr_dataset, media_num, varargin)
% NR_nr_read_tslice
%  Read segment of images associated with one particular media.
% SYNTAX
%
%  [y] = read_media ('all', nr_dataset, media_num);
%  [y] = read_media ('frames', nr_dataset, media_num, start, stop);
%  [y] = read_media (..., 'PropertyName', PropertyValue1, PropertyValue2, ...);
%  [y, cb, cr] = read_media (...);
%
% DESCRIPTION
%
%  Read part or all of the media associated with nr_dataset.media(media_num)
%  This function has three modes:
%   1. Mode 'all' reads the entire media
%   2. Mode 'frames' reads the specified range of frames (start to stop)
%           Specified frames must be within the available range
%           [nr_datset.media(media_num).start .. nr_datset.media(media_num).stop]
%           WARNING: interlaced video will return twice as many frames, due
%           to de-interlacing. 
%
%  By default, returns only pixels within the media's valid region.  
%
%  Return value 'Y' contains the read images as a 3-D matrix:  row, column,
%  time.  Return values 'Cb' and 'Cr' contain the color image planes. 
%
%  The following optional arguments may be appended: 
%
%  'region',top, left, bottom, right,
%                       Requested spatial region of interest, overriding
%                       the media's specified valid region. 
%  'interlace'          If the media is an interlaced video, return the raw pixels. 
%                       By default, interlaced videos are deinterlaced by 
%                       spliting into fields, and up-sampling each field to a full frame.
%                    
% EXAMPLE
%  [y] = read_media( 'all', nr_dataset, 57, 'region', 21, 21, 468, 700); % read entire video or image 
%  [y] = read_media( 'frames', nr_dataset, 3, 20, 280); % read frames 20 to 200
%
% REMARKS
%
% Color planes will be upsampled with pixel replication where necessary, so
% that Y, Cb, and Cr planes are all the same size. 
%
% Can read the folloowing formats:
%   - uncompressed AVI files (UYVY or RGB) with 'avi' suffix
%   - any video format supported by MATLAB function 'VideoReader'
%   - any image format supported by MATLAB function 'imread'

    if length(nr_dataset) > 1
        error('read_media must be called with exactly one dataset');
    end
    if length(media_num) > 1
        error('read_media must be called with exactly one media requested');
    end
    if media_num < 1 || media_num > length(nr_dataset.media)
        error('read_media: requested media number does not exist');
    end
    
    % abbreviate long variable name
    image_rows = nr_dataset.media(media_num).image_rows;
    image_cols = nr_dataset.media(media_num).image_cols;


    % figure out which frames to read
    if strcmp(mode,'all') 
        is_start = nr_dataset.media(media_num).start;
        is_stop = nr_dataset.media(media_num).stop;   
        base_argin = 1;
    elseif strcmp(mode,'frames') 
        is_start = varargin{1};
        is_stop = varargin{2};
        if is_start < nr_dataset.media(media_num).start || is_stop > nr_dataset.media(media_num).stop
            error('read_media: requested frames are out-of-bounds, beyond available limits');
        end
        base_argin = 3;
    else
        error('read_media mode not recognized');
    end

    total_frames = is_stop - is_start + 1;

    % error check
    if is_start < nr_dataset.media(media_num).start
        error('read_media: request to read before first available frame');
    end
    if is_stop > nr_dataset.media(media_num).stop
        error('read_media: request to read past last available frame');
    end


    % default values for all media options
    valid_top = nr_dataset.media(media_num).valid_top;
    valid_left = nr_dataset.media(media_num).valid_left;
    valid_bottom = nr_dataset.media(media_num).valid_bottom;
    valid_right = nr_dataset.media(media_num).valid_right;

    is_deinterlace = 1; % de-interlace by default

    % % loop, read other input arguments
    cnt = base_argin;
    while cnt + 3 <= nargin
        if strcmpi(varargin{cnt},'region') == 1
            valid_top = varargin{cnt+1};
            valid_left = varargin{cnt+2};
            valid_bottom = varargin{cnt+3};
            valid_right = varargin{cnt+4};

            if valid_top < 1 || valid_left < 1 || ...
                    valid_bottom > image_rows || ...
                    valid_right > image_cols
                error('ERROR: read_media, valid region outside image boundaries');
            end
            cnt = cnt + 5;
        elseif strcmpi(varargin{cnt},'interlace') == 1
            is_deinterlace = 0;
            cnt = cnt + 1;
        else
            error('Property value passed into read_media not recognized');
        end
    end

    % find file suffix, indicating type
    period = strfind(nr_dataset.media(media_num).file,'.');
    period = period(length(period));
    hold_suffix = nr_dataset.media(media_num).file(period+1:end);
    hold_suffix = deblank(hold_suffix); % eliminate trailing white space

    % loop through & read in the time-slice of images
    if strcmpi(hold_suffix,'avi')
        if (nargout >= 3)
            x = [nr_dataset.path nr_dataset.media(media_num).file];
            [all_y,all_cb,all_cr] = read_avi('YCbCr', x, ...
                'frames', is_start, is_stop, '128');

            % scale to destination monitor
            all_y  = image_scale(all_y,  image_rows, image_cols, false);
            all_cb = image_scale(all_cb, image_rows, image_cols, false);
            all_cr = image_scale(all_cr, image_rows, image_cols, false);
        else
            [all_y] = read_avi('YCbCr',[nr_dataset.path nr_dataset.media(media_num).file], ...
                'frames', is_start, is_stop, '128');

            % scale to destination monitor
            all_y = image_scale(all_y, image_rows, image_cols, false);
        end
    elseif (strcmpi(hold_suffix,'jpg') || strcmpi(hold_suffix, 'png') || strcmpi(hold_suffix, 'jpeg'))

        % read
        img1 = imread([nr_dataset.path nr_dataset.media(media_num).file]);

        % scale to destination monitor
        img2 = image_scale(img1, image_rows, image_cols, false);

        % color space conversion
        [rows,cols,planes] = size(img2);
        if planes == 3
            [tmp_y, tmp_cb, tmp_cr] = rgb2ycbcr_double(double(img2), '128', 'y_cb_cr');
        elseif planes == 1
            % greyscale image
            tmp_y = img2;
            tmp_cb = img2 * 0;
            tmp_cr = img2 * 0;
        else
            error('type of image file not recognized');
        end

        % replicate, as requested.
        all_y = nan(rows, cols, total_frames);
        all_cb = nan(rows, cols, total_frames);
        all_cr = nan(rows, cols, total_frames);
        for cnt = 1:total_frames
            all_y(:,:,cnt) = tmp_y;
            all_cb(:,:,cnt) = tmp_cb;
            all_cr(:,:,cnt) = tmp_cr;
        end
        clear tmp1 tmpcb tmpcr;
    else
        [all_y,all_cb,all_cr] = read_video([nr_dataset.path nr_dataset.media(media_num).file], is_start, is_stop);

        % scale to destination monitor
        all_y  = image_scale(all_y,  image_rows, image_cols, false);
        if nargout > 1
            all_cb = image_scale(all_cb, image_rows, image_cols, false);
            all_cr = image_scale(all_cr, image_rows, image_cols, false);
        end
    end


    % cut out valid region. Also convert to double precitions. 
    if ~isnan(valid_top) && ~isnan(valid_bottom) && ~isnan(valid_left) && ~isnan(valid_right)
        rows = valid_top:valid_bottom;
        cols = valid_left:valid_right;

        y = double (all_y(rows,cols,:));
        if nargout > 1
            cb = double (all_cb(rows,cols,:));
            cr = double (all_cr(rows,cols,:));
        end
    else
        y = single(all_y);
        if nargout > 1
            cb = single(all_cb);
            cr = single(all_cr);
        end
    end
    
    % deinterlace, if necessary and requested
    if is_deinterlace
        if strcmp(nr_dataset.media(media_num).video_standard,'interlace_lower_field_first') == 1 || ...
            strcmp(nr_dataset.media(media_num).video_standard,'interlace_upper_field_first') == 1

            [y] = split_into_fields(y, nr_dataset.media(media_num).video_standard);
            if nargout >= 3
                [cb] = split_into_fields(cb, nr_dataset.media(media_num).video_standard);
                [cr] = split_into_fields(cr, nr_dataset.media(media_num).video_standard);
            end
        end
    end

end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read a video using MATLAB utility, convert to YCbCr, with '128' option
function [all_y,all_cb,all_cr] = read_video(filename, start_frame, stop_frame)

    v = VideoReader(filename);

    % adjust 1st frame to read
    offset = (start_frame - 1) / v.FrameRate;
    v.CurrentTime = v.CurrentTime + offset;
    
    % make sure is RGB color space
    if ~strcmp(v.VideoFormat,'RGB24')
        error('color space of video file not recognized');
    end

    num_frames = stop_frame - start_frame + 1;
    all_y = zeros(v.Height, v.Width, num_frames);
    all_cb = zeros(v.Height, v.Width, num_frames);
    all_cr = zeros(v.Height, v.Width, num_frames);

    for cnt=1:num_frames
        tmp = readFrame(v);
        [y, cb, cr] = rgb2ycbcr_double(single(tmp), '128', 'y_cb_cr');

        all_y(:,:,cnt) = y;
        all_cb(:,:,cnt) = cb;
        all_cr(:,:,cnt) = cr;
    end
end



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [one, two] = split_into_fields(y, type)
% SPLIT_INTO_FIELDS
%  Splits one frame into two fields.
% SYNTAX
%  [upper lower] = split_into_fields(y);
%  [y_frame] = split_into_fields(y, 'interlace_lower_field_first');
%  [y_frame] = split_into_fields(y, 'interlace_upper_field_first');
% DESCRIPTION
%  If only the frame 'y' is input:
%    Split frame 'y' into field one ('one') and field two ('two').  Field two
%    contains the top line of the image; field one contains the second line
%    of the image.  For NTSC, field one occurs before field two in time.  For
%    PAL, the reverse is the case.  Y can be a time-slice of frames.
%
%    If image 'y' contains an odd number of rows, then the last (bottom) row
%    will be eliminated.  
%
%  If type flag is specified ('interlace_lower_field_first' or
%  'interlace_upper_field_first'), then the video will be split into
%  fields, each field will be converted to a frame (interpolating the
%  missing lines), and knit together into a single progressive stream. That
%  stream will be returned.
%
%  See also function 'join_into_frames'

    if ~exist('type','var')
        [row, col, time] = size(y);
        if mod(row,2)
            y = y(1:row-1,1:col,1:time);
            [row, col, time] = size(y);
        end
        y = reshape(y,2,row/2,col,time);
        two = squeeze(y(1,:,:,:));
        one = squeeze(y(2,:,:,:));
    else
        % find size of image
        [num_rows, num_cols,num_frames] = size(y);

        % reshape into fields
        y_temp = reshape( y, 2, num_rows/2, num_cols, num_frames );
        y = zeros(2, num_rows/2, num_cols, 2*num_frames);

        if strcmpi(type,'interlace_lower_field_first')
            early = 2;
            late = 1;
        elseif strcmpi(type,'interlace_upper_field_first')
            early = 1;
            late = 2;
        else
            error('Input type flag not recognized');
        end

        % form a progressive frame from each field
        y(1, :, :, 1:2:2*num_frames) = y_temp(early, :, :, :);
        y(2, :, :, 1:2:2*num_frames) = y_temp(early, :, :, :);
        y(1, :, :, 2:2:2*num_frames) = y_temp(late, :, :, :);
        y(2, :, :, 2:2:2*num_frames) = y_temp(late, :, :, :);

        % reshape back
        one = reshape( y, num_rows, num_cols, 2*num_frames);

    end


end












