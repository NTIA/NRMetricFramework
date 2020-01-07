function display_xyt(y_xyt, varargin)
% DISPLAY_XYT
%  Display a sequence of grayscale images from memory to the screen.  
%  Image coordinates are x (horizontal), y (vertical), and t (time).  
%  Options for interlaced playback, slow motion, and looping. 
% SYNTAX
%  display_xyt(y)
%  display_xyt(...,'Flag', ...)
% DEFINITION
%  display_xyt(y) displays to the screen a sequence of luminance 
%  images, 'y', having coordinates (row,col,time)
%  Optional flags are:
%  'interlace_lower_field_first' indicates that y contains interlaced images with the
%       lower field displayed earlier in time (e.g., D1 NTSC).  The time
%       history of fields will be displayed.
%  'interlace_upper_field_first' indicates that y interlaced images with the 
%       upper field displayed earlier in time (e.g., D1 Pal). The time
%       history of fields will be displayed.
%  'progressive' requests a progressive playback.  This is the default.  
%  'slowmo' requests slow motion playback, pausing 1 second after each
%       image display and beeping.
%   'subplot' don't open a new figure. Assume a figure is already open, and
%       display the image or video with no axes. 
% REMARKS
%  Routine tested.

is_lower_first = 1;
is_interlace = 0;
is_slowmo = 0;
is_subplot = 0;
is_repeat = 1;

if nargin > 1
    for cnt = 2:nargin
        if strcmp(varargin{cnt-1},'interlace_upper_field_first') == 1
            is_lower_first = 0;
            is_interlace = 1;
        elseif strcmp(varargin{cnt-1},'interlace_lower_field_first') == 1
            is_lower_first = 1;
            is_interlace = 1;
        elseif strcmp(varargin{cnt-1},'progressive') == 1
            is_interlace = 0;
        elseif strcmp(varargin{cnt-1},'slowmo') == 1
            is_slowmo = 1;
        elseif strcmp(varargin{cnt-1},'subplot') == 1
            is_subplot = 1;
        else
            error('display_xyt Flag not recognized');
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

    % reshape back
    y_xyt = reshape( y_xyt, num_rows, num_cols, 2*num_frames);

    clear y_temp ;
end


% find size of image
[num_rows, num_cols,num_frames] = size(y_xyt);

if ~is_subplot
    figure('Units', 'pixels', 'Position', [100 100 num_cols num_rows],...
        'Name','Display Greyscale XYT');
    set(gca, 'Position', [0 0 1 1]);
end
colormap(gray(256));

% 
if mod(num_rows,2) && is_interlace
    fprintf('Time-slice of images contains an odd number of rows.  Try again with the\n');
    fprintf('''progressive'' flag.  By default, time-slice presumed to contain interlace\n');
    return;
end

% loop through displaying this sequences as many times as wanted.
for loop = 1:is_repeat
	% loop through and display luminance images.
	for cnt = 1:num_frames
        % convert to RGB computer, same algorithm as ycbcr2rgb_double
        y = (y_xyt(:,:,cnt)-16)*1.164384;
        y = max(0, min(y,255))/255;
        
        if cnt == 1
            % display first frame
            wrap_rgb = cat(3,y,y,y);
            old_y = y;
            if loop == 1
                h = image(wrap_rgb);
            else
                set(h, 'CData', wrap_rgb)
                drawnow
            end
            if is_subplot
                axis 'off'
            end
        else
            % display previous frame.
            set(h, 'CData', wrap_rgb)
            drawnow
            if is_slowmo
                beep; 
                pause(1.0); 
            end
	
            % compute RGB for this frame (but wait to display it, so that
            % frames will be displayed more evenly in time)  Also wait to
            % display the interlaced reframed-frame.
            wrap_rgb = cat(3,y,y,y);
            pause (0.02);
            
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


