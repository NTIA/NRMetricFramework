function display_color_xyt(y_xyt, cb_xyt,cr_xyt, varargin)
% DISPLAY_COLOR_XYT
%  Display a sequence of color images from memory to the screen.  Image 
%  coordinates are x (horizontal), y (vertical), and t (time).  Options 
%  exist for interlaced playback, slow motion, and looping.
% SYNTAX
%  display_color_xyt(y,cb,cr)
%  display_color_xyt(...,'Flag', ...)
% DEFINITION
%  display_color_xyt(y,cb,cr) displays sequence of color images, 'y' is the 
%  luminance planes, 'cb' the Cb planes, and 'cr' the Cr planes.  Each must 
%  have identical coordinates (row,col,time).
%  Optional flags are:
%  'interlace_lower_field_first' indicates that y interlaced images have the
%       lower field displayed earlier in time (e.g., D1 NTSC).  The time
%       history of fields will be displayed.
%  'interlace_upper_field_first' indicates that y interlaced images have the 
%       upper field displayed earlier in time (e.g., D1 Pal). The time
%       history of fields will be displayed.
%  'progressive' requests a progressive playback.  This is the default.  
%  'slowmo' requests slow motion playback, pausing 1 second after each
%       image display and beeping.
%   'subplot' don't open a new figure. Assume a figure is already open, and
%       display the image or video with no axes. 
%  #,   where # is an integer greater than 1, requests that the image sequence 
%       be played repeatedly, # times.
% REMARKS
%  Routine tested.
%  Cb and Cr must contain values centered around zero (i.e., -128 to 127)


is_lower_first = 1;
is_interlace = 0;
is_slowmo = 0;
is_repeat = 1;
is_subplot = 0;

if nargin > 3
    for cnt = 4:nargin
        if strcmp(varargin{cnt-3},'interlace_upper_field_first') == 1
            is_lower_first = 0;
            is_interlace = 1;
        elseif strcmp(varargin{cnt-3},'interlace_lower_field_first') == 1
            is_lower_first = 1;
            is_interlace = 1;
        elseif strcmp(varargin{cnt-3},'progressive') == 1
            is_interlace = 0;
        elseif strcmp(varargin{cnt-3},'slowmo') == 1
            is_slowmo = 1;
        elseif strcmp(varargin{cnt-3},'subplot') == 1
            is_subplot = 1;
        elseif isnumeric(varargin{cnt-3})
            is_repeat = varargin{cnt-3};
        else
            error('display_color_xyt Flag not recognized');
        end
    end
end


% reshape video sequence into fields
if is_interlace
    % find size of image
    [num_rows, num_cols,num_frames] = size(y_xyt);
    
    % reshape into fields
    y_temp = reshape( y_xyt, 2, num_rows/2, num_cols, num_frames );
    y_xyt = zeros(2, num_rows/2, num_cols, 2*num_frames);
    cb_temp = reshape( cb_xyt, 2, num_rows/2, num_cols, num_frames );
    cb_xyt = zeros(2, num_rows/2, num_cols, 2*num_frames);
    cr_temp = reshape( cr_xyt, 2, num_rows/2, num_cols, num_frames );
    cr_xyt = zeros(2, num_rows/2, num_cols, 2*num_frames);
    
    if is_lower_first
        early = 2;
        late = 1;
    else
        early = 1;
        late = 2;
    end

    % form a progressive frame from each field
    y_xyt(1, :, :, 1:2:2*num_frames) = y_temp(early, :, :, :);
    y_xyt(2, :, :, 1:2:2*num_frames) = y_temp(early, :, :, :);
    y_xyt(1, :, :, 2:2:2*num_frames) = y_temp(late, :, :, :);
    y_xyt(2, :, :, 2:2:2*num_frames) = y_temp(late, :, :, :);

    cb_xyt(1, :, :, 1:2:2*num_frames) = cb_temp(early, :, :, :);
    cb_xyt(2, :, :, 1:2:2*num_frames) = cb_temp(early, :, :, :);
    cb_xyt(1, :, :, 2:2:2*num_frames) = cb_temp(late, :, :, :);
    cb_xyt(2, :, :, 2:2:2*num_frames) = cb_temp(late, :, :, :);

    cr_xyt(1, :, :, 1:2:2*num_frames) = cr_temp(early, :, :, :);
    cr_xyt(2, :, :, 1:2:2*num_frames) = cr_temp(early, :, :, :);
    cr_xyt(1, :, :, 2:2:2*num_frames) = cr_temp(late, :, :, :);
    cr_xyt(2, :, :, 2:2:2*num_frames) = cr_temp(late, :, :, :);
    
    % reshape back
    y_xyt = reshape( y_xyt, num_rows, num_cols, 2*num_frames);
    cb_xyt = reshape( cb_xyt, num_rows, num_cols, 2*num_frames);
    cr_xyt = reshape( cr_xyt, num_rows, num_cols, 2*num_frames);

    clear y_temp cb_temp cr_temp;
end

% find size of image
[num_rows, num_cols,num_frames] = size(y_xyt);

if ~is_subplot
    figure('Units', 'pixels', 'Position', [100 100 num_cols num_rows],'Name','Display Color XYT');
    set(gca, 'Position', [0 0 1 1]);
end
colormap(gray(256));

%
for loop = 1:is_repeat
    % loop through and display color images
	for cnt = 1:num_frames
        % convert to RGB computer, same algorithm as ycbcr2rgb_double
        y = (y_xyt(:,:,cnt)-16)*1.164384;
        cb = (cb_xyt(:,:,cnt))*2.017233;
        cr = (cr_xyt(:,:,cnt))*1.596027;
        red = cr+y;
        green = y-0.194208*cb-0.509370*cr;
        blue = cb+y;
        
        if cnt ~= 1
            % display previous frame.  Do this here instead of when it is
            % produced, so that frames come out at a more even rate.
            set(h, 'CData', wrap_rgb)
            drawnow
            
            % pause & beep if requesed.
            if is_slowmo
                beep;
                pause(1.0);
            end
        end
        
        % clip pixel values to be integers within the valid range.
        red = max(0, min(red,255)) / 255;
        green = max(0, min(green,255)) / 255;
        blue = max(0, min(blue,255)) / 255;
	
        if cnt == 1
            % display first frame
            wrap_rgb = cat(3,red,green,blue);
            old_red = red;
            old_green = green;
            old_blue = blue;
            if loop == 1
                h = image(wrap_rgb);
            else
                set(h, 'CData', wrap_rgb)
                drawnow
            end
            if is_subplot
                axis 'off'
            end
            % pause & beep if requesed.
            if is_slowmo
                beep;
                pause(1.0);
            end
        else 
            % compute RGB for this frame (but wait to display it, so that
            % frames will be displayed more evenly in time)
            wrap_rgb = cat(3,red,green,blue);
            pause(0.02);

        end
	end
	% display final frame.
	set(h, 'CData', wrap_rgb)
	drawnow
    
    % pause & beep if requesed.
    if is_slowmo
        beep;
        pause(1.0);
    end
end
