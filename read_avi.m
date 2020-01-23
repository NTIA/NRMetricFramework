function [o1, o2, o3, o4, o5] = read_avi( ret_val, varargin )
% readAvi
%   Reads an uncompressed AVI file of a variety of formats, including
%   the following:
%       10-bit : uyvy : yuy2 : yv12 : rgb
%   If FILENAME does not include an extension, then '.avi' will be used.
% SYNTAX
%   [info] = read_avi('Info',filename);
%   [c1,c2,c3] = read_avi(color_out,filename);
%   [...] = read_avi(...,'flag',...);
% DESCRIPTION
%   [info] = read_avi('Info',filename);
%       returns only a struct, containing information about the file.
%       This struct can then be passed as an argument to this function
%       preceded by the 'struct' flag, and the file will be read.
%   [c1,c2,c3] = read_avi(color_out,filename);
%       returns the color components of the frames read in from the file.
%       The color components will depend on color_out. If no frames are
%       requested in particular, only the first frame is read.
%   [...] = read_avi(...,'Flag',...);
%       designates a flag to be set inside the function. See below for a
%       complete list of possible flags.
% INPUT ARGUMENTS
%   color_out >
%   'Info'  -- return listing of header information (see aviinfo).
%   'RGB'   -- return image planes in the RGB colorspace.
%   'YCbCr' -- return image planes in the YCbCr colorspace.
%
%   filename >
%   Avi file to be opened. If the 'struct' flag has
%   already been given, do NOT also give a filename
%
%   flag >
%   'struct', avi_struct    A struct returned by aviinfo or by this
%                           function with the 'Info' property.
%   'sroi',top,left,bottom,right,   Spatial region of interest.  By 
%                                   default, all of each image is 
%                                   returned.
%   'frames',start,stop,    Specify the first and last frames, 
%                           inclusive, to be read ('start' and 'stop').
%                           By default, read first frame.
%   '128'               Subtract 128 from all Cb and Cr values.  By 
%                       default, Cb and Cr values are left in the 
%                       [0..255] range.
%   'interp'            Linearly interpolate Cb and Cr values.  By default, 
%                       color planes are pixel replicated.  Note:  
%                       Interpolation is slow. Only implemented for
%                       YUV colorspaces excepting YV12.
%   'audio',['frames' or 'seconds'], start, stop
%               Request audio be returned if it exists. If 'frames' are
%               requested, the audio for the given frames [1..NumFrames]
%               will be returned. If 'seconds' are requested, audio with
%               the given duration [0..TotalTime) will be returned. Feel
%               free to request more than is in the file; I handle it :)
% OUTPUT ARGUMENTS
%   c1 >
%   Depending on the color_out property, could be Info if 'Info', Y if
%   'YCbCr', or R if 'RGB'.
%
%   c2, c3 >
%   Depending on the color_out property, could be Cb and Cr if 'YCbCr'
%   or G and B if 'RGB'.
%
%   c4 >
%   If audio is requested and exists, this is the raw audio data,
%   separated by channels.
%
%   c5 >
%   if audio is requested and exists, this is the Audio Rate.
% EXAMPLES
%---[info] = read_avi('Info','twocops.avi');
%---[r,g,b] = read_avi('RGB','twocops.avi','frames',1,30);
%---[y,cb,cr] = read_avi('YCbCr','twocops.avi','frames',61,90,'128');
%---info = aviinfo('my.avi');
%   [r, g, b] = read_avi('RGB', 'struct', info);
%---[y,cb,cr,aud,rate] = read_avi('YCbCr','my.avi','audio','seconds',0,5);
% NOTES
%   When reading files with the YV12 fourcc, the cb and cr color
%   components will be extrapolated to fit the Y component matrix size.
%   The current extrapolation algorithm simply copies the cb and cr
%   values. A better implementation might include a bi-linear
%   interpolation.

% SIGNATURE
%   Programmer: Zebulon Fross
%   Version:    08/10/2010
%

% Initialization
is_whole_image  =  1;
frame_start     =  1;
frame_stop      =  1;
audio_start     =  0;
audio_stop      =  0;
used_frames     =  0;
sroi            = [];
is_sub128       =  0;
is_interp       =  0;
ret_info        =  0;
ret_ycbcr       =  1;
% Parse return information type flag
if strcmpi(ret_val,'info')
    ret_info = 1;
elseif strcmpi(ret_val,'RGB')
    ret_ycbcr = 0;
elseif ~strcmpi(ret_val,'YCbCr')
    error('Return type flag not recognized');
end

persistent info;

% Validate input/output.
error(nargoutchk(0,5,nargout));
error(nargchk(2,19,nargin));
try
    cnt=1;
    while cnt <= length(varargin),
        if ~ischar(varargin{cnt}),
            error('parameter not recognized');
        end
        if strcmpi(varargin(cnt),'struct') == 1,
            info = varargin{cnt+1};
            cnt = cnt + 2;
        elseif strcmpi(varargin(cnt),'sroi') == 1,
            sroi.top = varargin{cnt+1};
            sroi.left = varargin{cnt+2};
            sroi.bottom = varargin{cnt+3};
            sroi.right = varargin{cnt+4};
            is_whole_image = 0;
            cnt = cnt + 5;
        elseif strcmpi(varargin(cnt),'frames') == 1,
            frame_start = varargin{cnt+1};
            frame_stop = varargin{cnt+2};
            cnt = cnt + 3;
        elseif strcmp(varargin(cnt),'128') == 1,
            is_sub128 = 1;
            cnt = cnt + 1;
            if ~ret_ycbcr,
                error('RGB and ''128'' flag are incompatible');
            end
        elseif strcmpi(varargin(cnt),'interp') == 1,
            is_interp = 1;
            cnt = cnt + 1;
        elseif strcmpi(varargin(cnt),'audio') == 1,
            cnt = cnt + 1;
            if strcmpi(varargin(cnt),'frames') == 1,
                used_frames = 1;
            end
            audio_start = varargin{cnt+1};
            audio_stop  = varargin{cnt+2};
            cnt = cnt + 3;
        else
            % assume file name is given
            filename = varargin{cnt};
            [~,~,ext] = fileparts(filename);
            if isempty(ext)
                filename = strcat(filename,'.avi');
            end
            new_dir = dir(filename);
            if isempty(info) || ...
                    ~strcmp(info.Filename, filename) || ...
                    ~strcmp(info.FileModDate, new_dir.date) || ...
                    ~eq(info.FileSize, new_dir.bytes)
                %this alternate function provides bit data about the avi
                %which is not provided in the current matlab implementation
                info = view_alt_aviinfo(filename); 
            end
            cnt = cnt + 1;
        end
    end
catch e
    
    fprintf('Reading video file %s\n', filename);
    error(e.identifier, ...
        'Unable to parse input arguments. Please check calling syntax.');
end

% if frames were given for audio, convert frames to seconds
if used_frames == 1,
    audio_start = (audio_start-1)/info.FramesPerSecond;
    audio_stop  = audio_stop/info.FramesPerSecond;
end
% check for invalid audio request
if (audio_stop < audio_start)
    error('MATLAB:readavialt', 'invalid audio chunk request');
end

if ret_info == 1
    o1 = info;
    return ;
end

% TODO: Is this correct?
if ispc
    file = fopen(info.Filename, 'r', 'l');
else
    file = fopen(info.Filename, 'r', 'b');
end
assert(file >= 0);

% ensure frame request is valid
if frame_start <= 0 || frame_start > info.NumFrames
    error('frame numbers to read must be valid');
end
if frame_stop < frame_start || frame_stop > info.NumFrames
    error('frame numbers to read must be valid');
end

if is_whole_image,
    o1=zeros(info.Height,...
        info.Width,...
        frame_stop-frame_start+1,'single');
else
    o1=zeros(sroi.bottom-sroi.top+1,...
        sroi.right-sroi.left+1,...
        frame_stop-frame_start+1,'single');
end
if nargout > 1
    o2=o1;
    o3=o1;
    o4=[];
    o5= 0;
end

%% gather video data -------------------------------------------------
out_pos = 1;
% read in the requested frames
for ind = frame_start:frame_stop
    % seek to position of frame
    fseek(file, info.vidFrames(1, ind), -1);
    
    if ( strcmp(info.ColorType, 'UYVY') )
        if (strcmpi(info.Codec, 'UYVY') || ...
                strcmpi(info.Codec, 'ffds') || ...
                strcmpi(info.Codec, 'HDYC') || ...
                strcmpi(info.Codec, 'DIB '))
            [y,cb,cr] = read_uyvy_frame(file, is_whole_image, ...
                sroi, is_interp, ...
                info.Height, info.Width);
            %                 % One fluke AVI file had upsidedown images, and so needed
            %                 % images to be flipped. None of the ITS datasets have this
            %                 % problem, so this appears to have been a mistake.
            %                 if (strcmpi(info.Codec, 'DIB '))
            %                 % I am still not sure how to interpret DIB files
            %                    y  = flipud( y);
            %                    cb = flipud(cb);
            %                    cr = flipud(cr);
            %                 end
        elseif (strcmpi(info.Codec, 'v210'))
            [y, cb, cr] = ...
                read_10bit_uyvy(file, is_whole_image, ...
                sroi, is_interp, ...
                info.Height, info.Width);
        elseif (strcmpi(info.Codec, 'yuy2'))
            [y,cb,cr] = read_yuyv_frame(file, is_whole_image, ...
                sroi, is_interp, ...
                info.Height, info.Width);
        elseif (strcmpi(info.Codec, 'yv12'))
            [y, cb, cr] = read_yv12_frame(file, is_whole_image, ...
                sroi, is_interp, ...
                info.Height, info.Width);
            % if the codec is not one of the previous, we will resort to
            % the compressed file reader
        else
            % this piece of code is experimental for reading
            % compressed avi files. The mex file does not work on
            % 64-bit machines. On 32-bit machines, the program
            % returns slightly-faulty data.
            error('could not interpet avi codec');
            %                 try
            %                     eStr = ['The mex function could not read this AVI ' ...
            %                         'file. This could be because the mex function' ...
            %                         ' is not available or because the file''s ' ...
            %                         'codec is not installed on this system.'];
            %                     % determine the correct mex function to call
            %                     if ( strcmp(computer, 'PCWIN') )
            %                         [r, g, b] = read_compressed_avi_32(info.Filename, ...
            %                             ind, ...
            %                             info.Height, ...
            %                             info.Width);
            %                     else
            %                         eStr = ['Your operating system is not supported by' ...
            %                             ' our mex function. Please run this again ' ...
            %                             'on a 32-bit Windows machine.'];
            %                         error(eStr);
            %                     end
            %                     [y, cb, cr] ...
            %                         = rgb2ycbcr_double(double( r ), ...
            %                         double( g ), ...
            %                         double( b ));
            %                 catch e
            %                     rethrow(e);
            %                 end
        end
        % append y, cb, and cr to output variables
        if ret_ycbcr,
            o1(:,:,out_pos) = y;
            if nargout > 1,
                if is_sub128
                    cb = single(cb)-128;
                    cr = single(cr)-128;
                end
                o2(:,:,out_pos) = cb;
                o3(:,:,out_pos) = cr;
            end
        else
            [o1(:,:,out_pos),o2(:,:,out_pos),o3(:,:,out_pos)] ...
                = ycbcr2rgb_double(single(y),...
                single(cb),...
                single(cr));
        end
    elseif strcmp(info.ColorType, 'RGB'),
        if info.BitDepth == 24,
            [r,g,b] = read_rgb24_frame(file, is_whole_image, ...
                sroi, info.Height, ...
                info.Width);
        elseif info.BitDepth == 32,
            [r,g,b] ...
                = read_rgb32_frame(file, is_whole_image, sroi, ...
                info.Height, ...
                info.Width);
            % if the codec is not one of the previous, we will resort to
            % the compressed file reader
        else
            % this piece of code is experimental for reading
            % compressed avi files. The mex file does not work on
            % 64-bit machines. On 32-bit machines, the program
            % returns slightly-faulty data.
            error('could not interpet avi codec');
            %                 try
            %                     eStr = ['The mex function could not read this AVI ' ...
            %                         'file. This could be because the mex function' ...
            %                         ' is not available or because the file''s ' ...
            %                         'codec is not installed on this system.'];
            %                     % determine the correct mex function to call
            %                     if ( strcmp(computer, 'PCWIN') )
            %                         [r, g, b] = read_compressed_avi_32(info.Filename, ...
            %                             ind, ...
            %                             info.Height, ...
            %                             info.Width);
            %                     else
            %                         eStr = ['Your operating system is not supported by' ...
            %                             ' our mex function. Please run this again ' ...
            %                             'on a 32-bit Windows machine.'];
            %                         error(eStr);
            %                     end
            %                 catch e
            %                     rethrow(e);
            %                 end
        end
        
        if ~ret_ycbcr,
            o1(:,:,out_pos) = r;
            o2(:,:,out_pos) = g;
            o3(:,:,out_pos) = b;
        else
            [y, cb, cr] = rgb2ycbcr_double(r,g,b);
            o1(:,:,out_pos) = y;
            if nargout > 1,
                if is_sub128
                    cb = single(cb)-128;
                    cr = single(cr)-128;
                end
                o2(:,:,out_pos) = cb;
                o3(:,:,out_pos) = cr;
            end
        end
    else
        error('unsupported input format');
    end
    out_pos = out_pos + 1;
end

%% only return audio if requested and if it exists -------------------
if audio_stop > 0 && isfield(info, 'audFrames')
    data = [];
    
    % determine the datatype to read in
    BytesPerSample = info.BitsPerSample/8;
    if (BytesPerSample == 1),
        dtype='uchar'; % unsigned 8-bit
    elseif (BytesPerSample == 2),
        dtype='int16'; % signed 16-bit
    elseif (BytesPerSample == 3)
        dtype='bit24'; % signed 24-bit
    elseif (BytesPerSample == 4),
        % 32-bit 16.8 float (type 1 - 32-bit)
        if (strcmpi(info.AudioFormat, 'Format # 0x1'))
            dtype = 'bit32'; %signed 32-bit
            % 32-bit normalized floating point
        elseif (strcmpi(info.AudioFormat, 'Format # 0x3'))
            dtype = 'float'; % floating point
        elseif (strcmpi(info.AudioFormat, 'Format # 0xFFFE'))
            %32 Bit data with either integer or floating point numbers. Use
            %info.SubFormat to determine whether or not the audio data is
            %32 bit or 32 bit floating point.  Also, a check will still be
            %in place below just in case this information does not exist or
            %is something "weird".
            if(info.SubFormat == 1)
                %PCM data is contained, meaning that the data is 32 bit,
                %not floating point.
                dtype = 'bit32'; %signed 32-bit
            elseif(info.SubFormat == 3)
                %IEEE floating point data is contained, meaning that the
                %data is 32 bit floating point numbers.
                dtype = 'float'; % floating point
            else
                %The SubFormat is formatted in a way that isn't checked by
                %this program, it will be assumed that 32 bit will be used.
                dtype = 'bit32'; %signed 32-bit
                warning('SubFormat not formatted in a way this program understands.  Audio may be incorrect.');
            end
        else 
             dtype = 'bit32';
        end
    end

    skip_samples = uint32(audio_start*info.BytesPerSec/BytesPerSample);
    stop_samples = uint32(audio_stop*info.BytesPerSec/BytesPerSample);
    total_samples = (stop_samples - skip_samples)/info.NumAudioChannels;
    sample_count = 0;
    if sample_count < skip_samples
        ind = 0;
    else
        ind = 1;
    end
    % determine where to start reading the audio by skipping parts
    total_samples_thus_far = 0;
    while sample_count < skip_samples
        ind = ind + 1;
        sz = info.audFrames(2, ind);
        % Total samples in a chunk = size of chunk / Bytes per sample
        TotalSamples = floor(sz/BytesPerSample);
        sample_count = sample_count + TotalSamples;
        total_samples_thus_far = total_samples_thus_far + TotalSamples;
    end
    % determine how much needs to be skipped in the initial chunk
    % seek to initial chunk and skip necessary samples
    
    if(ind == 1)
        fseek(file, info.audFrames(1, ind), -1);
        fseek(file, floor(double(skip_samples)*BytesPerSample), 0);
        
        if(info.NumAudioChannels > 2)
            %Get a Reference Size to know how many samples you need to
            %actually have.
            
            data = [data fread(file, [info.NumAudioChannels, ...
                floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                /(BytesPerSample*info.NumAudioChannels))], dtype)];
            samples_needed = size(data,2);
            %Clear Data
            data = [];
            
            %Now grab all the data in the full chunk and chop off the not
            %needed data in the beginning.
            fseek(file, info.audFrames(1, ind), -1);
            data = [data fread(file, [info.NumAudioChannels, ...
                floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                /(BytesPerSample*info.NumAudioChannels))], dtype)];
            data = data(:,(size(data,2)-samples_needed+1):size(data,2));
            if(size(data,2) ~= samples_needed)
                %These two HAVE to be equal for the seeking through the
                %audio to be correct.
                error('Seeking through Audio data has failed!');
            end
            ind = ind + 1;
            try
                fseek(file, info.audFrames(1, ind), -1);
            catch
                %No more audio in the file, it was all read in.  That's
                %fine, this will be taken care of down below.
            end
        end
    else
        %Re-adjust skip_samples since we are not starting at the beginning
        %of the clip.
        skip_samples_in_file = skip_samples - (total_samples_thus_far - TotalSamples);
        if(skip_samples < 0)
            error('Skip Samples was not calculated correctly')
        end
        fseek(file, info.audFrames(1, ind), -1);
        fseek(file, floor(double(skip_samples_in_file)*BytesPerSample), 0);
        
        %Ok, so when 6 channel audio is present, seeking in the file messes
        %up the order of the audio channels for the first sample that is
        %read in.  Therefore, this program will read the whole chunk in and
        %then only store the number of samples that is needed.
        if(info.NumAudioChannels > 2)
            %Get a Reference Size to know how many samples you need to
            %actually have.
            
            data = [data fread(file, [info.NumAudioChannels, ...
                floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                /(BytesPerSample*info.NumAudioChannels))], dtype)];
            samples_needed = size(data,2);
            %Clear Data
            data = [];
            
            %Now grab all the data in the full chunk and chop off the not
            %needed data in the beginning.
            fseek(file, info.audFrames(1, ind), -1);
            data = [data fread(file, [info.NumAudioChannels, ...
                floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                /(BytesPerSample*info.NumAudioChannels))], dtype)];
            data = data(:,(size(data,2)-samples_needed+1):size(data,2));
            if(size(data,2) ~= samples_needed)
                %These two HAVE to be equal for the seeking through the
                %audio to be correct.
                error('Seeking through Audio data has failed!');
            end
            ind = ind + 1;
            try
                fseek(file, info.audFrames(1, ind), -1);
            catch
                %No more audio in the file, it was all read in.  That's
                %fine, this will be taken care of down below.
            end
        end
    end
    
    % while we haven't read in all that has been requested
    while size(data, 2) < total_samples
        if(isempty(data))
            %Dividing has to do with staying within the audio region!
            %Otherwise, it goes outside of the audio region and noise
            %is added.
            data = [data fread(file, [info.NumAudioChannels, ...
                floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                /(BytesPerSample*info.NumAudioChannels))], dtype)];
        else
            data = [data fread(file, [info.NumAudioChannels, ...
                    floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                    /(BytesPerSample*info.NumAudioChannels))], dtype)];
        end

        ind = ind + 1;
        % break out if there is no more audio to read. We won't
        % penalize for users requesting too much.
        if (ind > size(info.audFrames, 2))
            break;
        end
        fseek(file, info.audFrames(1, ind), -1);
    end
    
    %Chop off extra data before scaling occurs.  This has been moved from
    %the bottom of this function to here.  This is because if the program
    %read to much and left the audio section of the data, noise enters the
    %data.  This noise needs to be removed before the data can be
    %normalized.  Thus, this is what is accomplished here.
    if size(data, 2) < total_samples
        total_samples = size(data, 2);
    end
    % truncate the output just in case we read too much
    data = data(:, 1:total_samples);
    
    data = data';
    
    % Normalize data range: min will hit -1, max will not quite hit +1.
    if BytesPerSample==1,
        data = (data-128)/128;  % [-1,1)
    elseif BytesPerSample==2,
        data = data/32768;      % [-1,1)
    elseif BytesPerSample==3,
        data = data/(2^23);     % [-1,1)
    elseif BytesPerSample==4,
        % Type 3 32-bit is already normalized
        if(~strcmpi(info.AudioFormat, 'Format # 0x3') && info.SubFormat ~= 3)
           data = data/(2^31); % [-1,1)
        end
    end
    
    %Only needed for 32 bit audio - This checks if the 32 bit audio should
    %be int32 (default) or if it should be float 32 bit.  While this can
    %be known from the aviinfo function (info.AudioFormat = 0x3) it is
    %unknown if the audio format is WAVE_FORMAT_EXTENSIBLE(0xfffe).
    %Therefore, this needs to be checked, this function is responsible for
    %checking.  This also provides a "check" for info.SubFormat, just
    %in case it was not formatted or not formatted correctly.
    if(strcmpi(info.AudioFormat, 'Format # 0xFFFE') && (strcmpi(dtype,'bit32') || strcmpi(dtype,'float')))
        if(max(max(isnan(data))) == 1) %The assumed format was not correct.
            %32 bit float will be used
            
            skip_samples = uint32(audio_start*info.BytesPerSec/BytesPerSample);
            stop_samples = uint32(audio_stop*info.BytesPerSec/BytesPerSample);
            total_samples = (stop_samples - skip_samples)/info.NumAudioChannels;
            sample_count = 0;
            if sample_count < skip_samples
                ind = 0;
            else
                ind = 1;
            end
            % determine where to start reading the audio by skipping parts
            total_samples_thus_far = 0;
            while sample_count < skip_samples
                ind = ind + 1;
                sz = info.audFrames(2, ind);
                % Total samples in a chunk = size of chunk / Bytes per sample
                TotalSamples = floor(sz/BytesPerSample);
                sample_count = sample_count + TotalSamples;
                total_samples_thus_far = total_samples_thus_far + TotalSamples;
            end
            % determine how much needs to be skipped in the initial chunk
            % seek to initial chunk and skip necessary samples
            
            if(strcmpi(dtype,'bit32'))
                data = [];
                dtype = 'float';
            else
                data = [];
                dtype = 'bit32';
            end
            
            if(ind == 1)
                fseek(file, info.audFrames(1, ind), -1);
                fseek(file, floor(double(skip_samples)*BytesPerSample), 0);
                
                if(info.NumAudioChannels > 2)
                    %Get a Reference Size to know how many samples you need to
                    %actually have.
                    
                    data = [data fread(file, [info.NumAudioChannels, ...
                        floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                        /(BytesPerSample*info.NumAudioChannels))], dtype)];
                    samples_needed = size(data,2);
                    %Clear Data
                    data = [];
                    
                    %Now grab all the data in the full chunk and chop off the not
                    %needed data in the beginning.
                    fseek(file, info.audFrames(1, ind), -1);
                    data = [data fread(file, [info.NumAudioChannels, ...
                        floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                        /(BytesPerSample*info.NumAudioChannels))], dtype)];
                    data = data(:,(size(data,2)-samples_needed+1):size(data,2));
                    if(size(data,2) ~= samples_needed)
                        %These two HAVE to be equal for the seeking through the
                        %audio to be correct.
                        error('Seeking through Audio data has failed!');
                    end
                    ind = ind + 1;
                    try
                        fseek(file, info.audFrames(1, ind), -1);
                    catch
                        %No more audio in the file, it was all read in.  That's
                        %fine, this will be taken care of down below.
                    end
                end
            else
                %Re-adjust skip_samples since we are not starting at the beginning
                %of the clip.
                skip_samples_in_file = skip_samples - (total_samples_thus_far - TotalSamples);
                if(skip_samples < 0)
                    error('Skip Samples was not calculated correctly')
                end
                fseek(file, info.audFrames(1, ind), -1);
                fseek(file, floor(double(skip_samples_in_file)*BytesPerSample), 0);
                
                %Ok, so when 6 channel audio is present, seeking in the file messes
                %up the order of the audio channels for the first sample that is
                %read in.  Therefore, this program will read the whole chunk in and
                %then only store the number of samples that is needed.
                if(info.NumAudioChannels > 2)
                    %Get a Reference Size to know how many samples you need to
                    %actually have.
                    
                    data = [data fread(file, [info.NumAudioChannels, ...
                        floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                        /(BytesPerSample*info.NumAudioChannels))], dtype)];
                    samples_needed = size(data,2);
                    %Clear Data
                    data = [];
                    
                    %Now grab all the data in the full chunk and chop off the not
                    %needed data in the beginning.
                    fseek(file, info.audFrames(1, ind), -1);
                    data = [data fread(file, [info.NumAudioChannels, ...
                        floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                        /(BytesPerSample*info.NumAudioChannels))], dtype)];
                    data = data(:,(size(data,2)-samples_needed+1):size(data,2));
                    if(size(data,2) ~= samples_needed)
                        %These two HAVE to be equal for the seeking through the
                        %audio to be correct.
                        error('Seeking through Audio data has failed!');
                    end
                    ind = ind + 1;
                    try
                        fseek(file, info.audFrames(1, ind), -1);
                    catch
                        %No more audio in the file, it was all read in.  That's
                        %fine, this will be taken care of down below.
                    end
                end
            end
            
            % while we haven't read in all that has been requested
            while size(data, 2) < total_samples
                if(isempty(data))
                    %Dividing has to do with staying within the audio region!
                    %Otherwise, it goes outside of the audio region and noise
                    %is added.
                    data = [data fread(file, [info.NumAudioChannels, ...
                        floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                        /(BytesPerSample*info.NumAudioChannels))], dtype)];
                else
                    data = [data fread(file, [info.NumAudioChannels, ...
                        floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                        /(BytesPerSample*info.NumAudioChannels))], dtype)];
                end
                
                ind = ind + 1;
                % break out if there is no more audio to read. We won't
                % penalize for users requesting too much.
                if (ind > size(info.audFrames, 2))
                    break;
                end
                fseek(file, info.audFrames(1, ind), -1);
            end
            
            if size(data, 2) < total_samples
                total_samples = size(data, 2);
            end
            % truncate the output just in case we read too much
            data = data(:, 1:total_samples);
            
            data = data';
            
            if(strcmpi(dtype,'bit32'))
                data = data/(2^31); % [-1,1)
            end
        else %Check the histogram of the audio output.  If Gaussian in 
             %shape then everything is ok.  If two big peaks, the wrong
             %format was used.  32 bit float will be used.
            two_peaks = 0;
            peak_left = 0;
            peak_right = 0;
           
            %Obtain the histogram
            max_chan = [0,0];
            for i = 1:info.NumAudioChannels
                %Make sure the channel is not just all zeros
                temp = max(max(data(:,i)));
                if(temp > max_chan(1,1))
                    max_chan(1,1) = temp;
                    max_chan(1,2) = i;
                end
            end
             
            clear temp
            temp = histc(data(:,max_chan(1,2)),[min(min(data)):.01:max(max(data))]);
            
            %check if two peaks exist.
            %Split the histogram into two parts (the peaks will be on
            %either end of the spectrum if the wrong format was used.
            temp1 = temp(1:round((size(temp,1))/4));
            temp2 = temp(round(size(temp,1)*(3/4)):size(temp));
            temp3 = temp(round(size(temp,1)*(1/4)):round(size(temp,1)*(3/4)));
            
            %Set middle peak value for comparison
            middle_peak = max(temp3);
            
            %If a side peak is higher than the middle peak or is within 50%
            %of the middle_peak in value, more than one peak exists.
            if(max(temp1) > middle_peak || max(temp1) > (middle_peak - floor(middle_peak*.5)))
                %A peak on the left side exists
                peak_left = 1;
            end
            
            if(max(temp2) > middle_peak || max(temp2) > (middle_peak - floor(middle_peak*.5)))
                %A peak on the right side exists
                peak_right = 1;
            end
            
            if(peak_left == 1 && peak_right == 1)
                %The wrong format was used!
                two_peaks = 1;
                display('32 Bit Floating Point Audio Has Been Detected');
            elseif(peak_left == 1 || peak_right == 1)
                %Only one peak exists which is strange
                warning('Only one peak detected and its not centered!  Audio may not be correct!');
            end
            
            if(two_peaks == 1)
                %Audio format was wrong, use 32 bit floating point format.
                
                skip_samples = uint32(audio_start*info.BytesPerSec/BytesPerSample);
                stop_samples = uint32(audio_stop*info.BytesPerSec/BytesPerSample);
                total_samples = (stop_samples - skip_samples)/info.NumAudioChannels;
                sample_count = 0;
                if sample_count < skip_samples
                    ind = 0;
                else
                    ind = 1;
                end
                % determine where to start reading the audio by skipping parts
                total_samples_thus_far = 0;
                while sample_count < skip_samples
                    ind = ind + 1;
                    sz = info.audFrames(2, ind);
                    % Total samples in a chunk = size of chunk / Bytes per sample
                    TotalSamples = floor(sz/BytesPerSample);
                    sample_count = sample_count + TotalSamples;
                    total_samples_thus_far = total_samples_thus_far + TotalSamples;
                end
                % determine how much needs to be skipped in the initial chunk
                % seek to initial chunk and skip necessary samples
                
                if(strcmpi(dtype,'bit32'))
                    data = [];
                    dtype = 'float';
                else
                    data = [];
                    dtype = 'bit32';
                end
                
                if(ind == 1)
                    fseek(file, info.audFrames(1, ind), -1);
                    fseek(file, floor(double(skip_samples)*BytesPerSample), 0);
                    
                    if(info.NumAudioChannels > 2)
                        %Get a Reference Size to know how many samples you need to
                        %actually have.
                        
                        data = [data fread(file, [info.NumAudioChannels, ...
                            floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                            /(BytesPerSample*info.NumAudioChannels))], dtype)];
                        samples_needed = size(data,2);
                        %Clear Data
                        data = [];
                        
                        %Now grab all the data in the full chunk and chop off the not
                        %needed data in the beginning.
                        fseek(file, info.audFrames(1, ind), -1);
                        data = [data fread(file, [info.NumAudioChannels, ...
                            floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                            /(BytesPerSample*info.NumAudioChannels))], dtype)];
                        data = data(:,(size(data,2)-samples_needed+1):size(data,2));
                        if(size(data,2) ~= samples_needed)
                            %These two HAVE to be equal for the seeking through the
                            %audio to be correct.
                            error('Seeking through Audio data has failed!');
                        end
                        ind = ind + 1;
                        try
                            fseek(file, info.audFrames(1, ind), -1);
                        catch
                            %No more audio in the file, it was all read in.  That's
                            %fine, this will be taken care of down below.
                        end
                    end
                else
                    %Re-adjust skip_samples since we are not starting at the beginning
                    %of the clip.
                    skip_samples_in_file = skip_samples - (total_samples_thus_far - TotalSamples);
                    if(skip_samples < 0)
                        error('Skip Samples was not calculated correctly')
                    end
                    fseek(file, info.audFrames(1, ind), -1);
                    fseek(file, floor(double(skip_samples_in_file)*BytesPerSample), 0);
                    
                    %Ok, so when 6 channel audio is present, seeking in the file messes
                    %up the order of the audio channels for the first sample that is
                    %read in.  Therefore, this program will read the whole chunk in and
                    %then only store the number of samples that is needed.
                    if(info.NumAudioChannels > 2)
                        %Get a Reference Size to know how many samples you need to
                        %actually have.
                        
                        data = [data fread(file, [info.NumAudioChannels, ...
                            floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                            /(BytesPerSample*info.NumAudioChannels))], dtype)];
                        samples_needed = size(data,2);
                        %Clear Data
                        data = [];
                        
                        %Now grab all the data in the full chunk and chop off the not
                        %needed data in the beginning.
                        fseek(file, info.audFrames(1, ind), -1);
                        data = [data fread(file, [info.NumAudioChannels, ...
                            floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                            /(BytesPerSample*info.NumAudioChannels))], dtype)];
                        data = data(:,(size(data,2)-samples_needed+1):size(data,2));
                        if(size(data,2) ~= samples_needed)
                            %These two HAVE to be equal for the seeking through the
                            %audio to be correct.
                            error('Seeking through Audio data has failed!');
                        end
                        ind = ind + 1;
                        try
                            fseek(file, info.audFrames(1, ind), -1);
                        catch
                            %No more audio in the file, it was all read in.  That's
                            %fine, this will be taken care of down below.
                        end
                    end
                end
                
                % while we haven't read in all that has been requested
                while size(data, 2) < total_samples
                    if(isempty(data))
                        %Dividing has to do with staying within the audio region!
                        %Otherwise, it goes outside of the audio region and noise
                        %is added.
                        data = [data fread(file, [info.NumAudioChannels, ...
                            floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                            /(BytesPerSample*info.NumAudioChannels))], dtype)];
                    else
                        data = [data fread(file, [info.NumAudioChannels, ...
                            floor((info.audFrames(1,ind)+info.audFrames(2,ind)-ftell(file))...
                            /(BytesPerSample*info.NumAudioChannels))], dtype)];
                    end
                    
                    ind = ind + 1;
                    % break out if there is no more audio to read. We won't
                    % penalize for users requesting too much.
                    if (ind > size(info.audFrames, 2))
                        break;
                    end
                    fseek(file, info.audFrames(1, ind), -1);
                end
                
                if size(data, 2) < total_samples
                    total_samples = size(data, 2);
                end
                % truncate the output just in case we read too much
                data = data(:, 1:total_samples);
                
                data = data';
                
                if(strcmpi(dtype,'bit32'))
                    data = data/(2^31); % [-1,1)
                end
            end
        end
    end     
            
    % return only what was requested
    o4 = data;
    if size(o4, 1) < total_samples
        total_samples = size(o4, 1);
    end
    % truncate the output just in case we read too much
    o4 = o4(1:total_samples, :);
    % give the user the audio rate
    o5 = info.AudioRate;
    
    if(info.BitsPerSample == 32)
        %Need to let the AVI write function know whether the 32 bit audio
        %is floating point or not.  This information will be placed in o5
        %which displays the audio rate.  This was chosen because it is the
        %only returnable item that doesn't contain video or audio data.
        if(strcmpi(dtype,'bit32'))
            %Its 32 bit (not floating point)
            o5 = [info.AudioRate, 0];
        else
            %Its 32 bit floating point
            o5 = [info.AudioRate, 1];
        end
    end
            
end

fclose(file);
return ;

%% -----------------------------------------------------------------------
function [r,g,b] ...
    = read_rgb24_frame(fid, is_whole_image, sroi, num_rows, num_cols)
% Read one RGB24 frame

% read in image
temp = readAndCheck(fid, [3*num_cols,num_rows], '*uint8');

% flip.
temp = temp(:,num_rows:-1:1);

% pick off the planes
temp = reshape(temp', num_rows, 3, num_cols);

b = single(squeeze(temp(:,1,:)));
g = single(squeeze(temp(:,2,:)));
r = single(squeeze(temp(:,3,:)));

if ~is_whole_image,
    r = r(sroi.top:sroi.bottom, sroi.left:sroi.right);
    g = g(sroi.top:sroi.bottom, sroi.left:sroi.right);
    b = b(sroi.top:sroi.bottom, sroi.left:sroi.right);
end
return ;

%% -----------------------------------------------------------------------
function [r,g,b] = read_rgb32_frame(fid, is_whole_image, ...
    sroi, num_rows, num_cols)
% Read one RGB24 frame

% read in image
temp = readAndCheck(fid, [4*num_cols,num_rows], '*uint8');

% flip.
temp = temp(:,num_rows:-1:1);

% pick off the planes
temp = reshape(temp', num_rows, 4, num_cols);

b = single(squeeze(temp(:,1,:)));
g = single(squeeze(temp(:,2,:)));
r = single(squeeze(temp(:,3,:)));

if ~is_whole_image,
    r = r(sroi.top:sroi.bottom, sroi.left:sroi.right);
    g = g(sroi.top:sroi.bottom, sroi.left:sroi.right);
    b = b(sroi.top:sroi.bottom, sroi.left:sroi.right);
end
return ;

%% -----------------------------------------------------------------------
function [y,cb,cr] = read_uyvy_frame(fid, is_whole_image, sroi, ...
    is_interp, num_rows, num_cols)
% read one YCbCr frame

% read in image
data = readAndCheck(fid, [2*num_cols, num_rows], '*uint8');
% pick off the Y plane (luminance)
temp = reshape(data', num_rows, 2, num_cols);
y = squeeze(temp(:,2,:));

% If color image planes are requested, pick those off and perform
% pixel replication to upsample horizontally by 2.
temp = reshape(data,4,num_rows*num_cols/2);

cb = reshape(temp(1,:),num_cols/2,num_rows)';
cb = [cb ; cb];
cb = reshape(cb, num_rows, num_cols);

cr = reshape(temp(3,:),num_cols/2,num_rows)';
cr = [cr ; cr];
cr = reshape(cr, num_rows, num_cols);

% Interpolate, if requested
if is_interp == 1,
    for i=2:2:num_cols-2,
        % Bug fix 3/16/09
        cb(:,i) = uint8(round( ...
            (double(cb(:,i-1)) + double(cb(:,i+1)))/2));
        % Bug fix 3/16/09
        cr(:,i) = uint8(round( ...
            (double(cr(:,i-1)) + double(cr(:,i+1)))/2));
    end
end

if ~is_whole_image,
    y = y(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
    if nargout == 3,
        cb = cb(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
        cr = cr(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
    end
end
return ;

%% -----------------------------------------------------------------------
function [y,cb,cr] = read_yuyv_frame(fid, is_whole_image, sroi, ...
    is_interp, num_rows, num_cols)
% read one YCbCr frame (yuy2 format)

% read in image
data = readAndCheck(fid, [2*num_cols, num_rows], '*uint8');
% pick off the Y plane (luminance)
temp = reshape(data', num_rows, 2, num_cols);
y = squeeze(temp(:,1,:));

% If color image planes are requested, pick those off and perform
% pixel replication to upsample horizontally by 2.
temp = reshape(data,4,num_rows*num_cols/2);

cb = reshape(temp(2,:),num_cols/2,num_rows)';
cb = [cb ; cb];
cb = reshape(cb, num_rows, num_cols);

cr = reshape(temp(4,:),num_cols/2,num_rows)';
cr = [cr ; cr];
cr = reshape(cr, num_rows, num_cols);

% Interpolate, if requested
if is_interp == 1,
    for i=2:2:num_cols-2,
        % Bug fix 3/16/09
        cb(:,i) = uint8(round( ...
            (double(cb(:,i-1)) + double(cb(:,i+1)))/2));
        % Bug fix 3/16/09
        cr(:,i) = uint8(round( ...
            (double(cr(:,i-1)) + double(cr(:,i+1)))/2));
    end
end

if ~is_whole_image,
    y = y(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
    if nargout == 3,
        cb = cb(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
        cr = cr(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
    end
end
return ;

%% -----------------------------------------------------------------------
function [y,cb,cr] = read_yv12_frame(fid, is_whole_image, sroi, ...
    is_interp, num_rows, num_cols)
% read one YCbCr frame (yv12 format - http://fourcc.org/yuv.php#YV12)

% read in Y plane (luminance)
y = readAndCheck(fid, [num_cols, num_rows], '*uint8')';

% If color image planes are requested, read them in from the
% file and resample them
cr = readAndCheck(fid, num_cols/2 * num_rows/2, '*uint8');
cr = [cr, cr];
cr = reshape(cr', num_cols, num_rows/2)';
cr = [cr, cr];
cr = reshape(cr', num_cols, num_rows)';

cb = readAndCheck(fid, num_cols/2 * num_rows/2, '*uint8');
cb = [cb, cb];
cb = reshape(cb', num_cols, num_rows/2)';
cb = [cb, cb];
cb = reshape(cb', num_cols, num_rows)';

% cannot interpolate yv12
if is_interp == 1,
    error('Cannot interpolate yv12 format');
end

if ~is_whole_image,
    y = y(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
    if nargout == 3,
        cb = cb(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
        cr = cr(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
    end
end
return ;

%% -----------------------------------------------------------------------
function [y,cb,cr] = read_10bit_uyvy(fid, is_whole_image, sroi, ...
    is_interp, num_rows, num_cols)
% read one YCbCr frame from 10-bit data
% NOTE: Look at the following site for explanation:
% http://developer.apple.com/quicktime/icefloe/dispatch019.html#v210

global data;
% Picture of what the bytes look like coming in: 1 char = 1 bit
%   ///-CB-/// ////-Y-/// ///-CR-/// XX     - 1st 32 bits
%   ////-Y-/// ///-CB-/// ////-Y-/// XX     - 2nd 32 bits
%   ///-CR-/// ////-Y-/// ///-CB-/// XX     - 3rd 32 bits
%   ////-Y-/// ///-CR-/// ////-Y-/// XX     - 4th 32 bits

% read in image
sz = num_rows*num_cols*2;
% reads three 10-bit fields and then skips 2 bits. Nifty, right?
data = fread(fid, sz, '3*ubit10', 2);

y = data(2:2:sz);
cb= data(1:4:sz);
cr= data(3:4:sz);

% because this is 10-bit data, the bits need to be shifted right
% 2 places to turn it into 8-bit data.
y  = single(y)/4;
cb = single(cb)/4;
cr = single(cr)/4;

% reshape the extracted information
y = reshape(y, num_cols, num_rows)';

cb = reshape(cb,num_cols/2,num_rows)';
cb = [cb ; cb];
cb = reshape(cb,num_rows,num_cols);

cr = reshape(cr,num_cols/2,num_rows)';
cr = [cr ; cr];
cr = reshape(cr,num_rows,num_cols);

% Interpolate, if requested
if is_interp == 1,
    for i=2:2:num_cols-2,
        % Bug fix 3/16/09
        cb(:,i) = (cb(:,i-1) + cb(:,i+1))/2;
        % Bug fix 3/16/09
        cr(:,i) = (cr(:,i-1) + cr(:,i+1))/2;
    end
end

if ~is_whole_image,
    y = y(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
    if nargout == 3,
        cb = cb(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
        cr = cr(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
    end
end
return ;

%% -----------------------------------------------------------------------
function data = readAndCheck( file, num, datatype )
% Reads data from the specified file
[data, count] = fread(file, num, datatype);
% quick fix for data read into 2D matrices. This needs to be made
% more general though
if (size(num, 2) > 1)
    num = num(1,1)*num(1,2);
end
assert( eq( count, num) );
return ;





function info = view_alt_aviinfo( filename )
%% Reads the header of an AVI file and returns a structure,
% holding all the important information of the header in the following
% format:
%
%   The set of fields for FILEINFO are:
%   
%   Filename           - A string containing the name of the file.
%
%   FileModDate        - A string containing the modification date of the 
%                        file.
%   		      
%   FileSize           - An integer indicating the size of the file in 
%                        bytes.
%
%   Codec              - A four-character code, representing the file's
%                        compression type.
%   		      
%   FramesPerSecond    - An integer indicating the desired frames per 
%                     	 second during playback.
%
%   NumFrames          - An integer indicating the total number of frames 
%                     	 in the movie.
%   		      
%   Height             - An integer indicating the height of AVI movie in
%                     	 pixels.
%   		      
%   Width              - An integer indicating the width of AVI movie in
%                        pixels.
%   		      
%   ImageType          - A string indicating the type of image; either
%                     	 'truecolor' for a truecolor (RGB) image, or
%                     	 'indexed', for an indexed image.
%   		      
%   VideoCompression   - A string containing the compressor used to  
%                     	 compress the AVI file.   If the compressor is 
%                     	 not Microsoft Video 1, Run-Length Encoding, 
%                     	 Cinepak, or Intel Indeo, the four character code 
%                        is returned.
%		      
%   Quality            - A number between 0 and 100 indicating the video
%                     	 quality in the AVI file.  Higher quality numbers
%                     	 indicate higher video quality, where lower
%                     	 quality numbers indicate lower video quality.  
%                     	 This value is not always set in AVI files and 
%                     	 therefore may be inaccurate.
%
%   NumColormapEntries - The number of colors in the colormap. For a
%                        truecolor image this value is zero.
%
%   BitDepth           - A double representing the bit depth of the video.
%
%   ColorType          - A string indicating the video's colorspace.
%
%   vidFrames          - A 2x[NumFrames] matrix containing offsets and
%                        sizes of all frames in the AVI file.
%
% If AUDIO is present in the file, the following fields we will be added:
%
%   AudioFormat        - A string indicating the format in which the
%                        audio is stored.
%
%   AudioRate          - The audio's sampling rate.
%
%   NumAudioChannels   - The number of audio channels in the file.
%
%   BytesPerSec        - The number of bytes per second for audio. This
%                        is mostly for internal use.
%
%   BlockAlign         - A number indicating the block alignment. This is
%                        mostly for internal use to compute BitsPerSample.
%
%   SampleSize         - The size of an audio sample.
%
%   BufferSize         - The size of one audio data chunk.
%
%   BitsPerSample      - The number of bits per sample (per channel).
%
%   audFrames          - A 2x[number of audio chunks] matrix, containing
%                        the offsets and sizes of all audio chunks in the
%                        file.
% EXAMPLES:
% Read in an AVI file to determine it's frame rate
%   % use aviinfo to read file and store in structure
%   inf = aviinfo('my_file.avi');
%   inf.FramesPerSecond
%
% Output:
%   ans = 
%       29.9700
%
% REFERENCES:
%   http://the-labs.com/Video/odmlff2-avidef.pdf
%       Offers a detailed description of the AVI file format.
%
%   http://abcavi.kibi.ru/docs/riff2.pdf
%       An excellent reference for registered AVI audio formats.
%
%   http://www.jmcgowan.com/avi.html#WinProg
%       A not as detailed but easy to understand reference on the AVI
%       file format.
%
%   http://developer.apple.com/quicktime/icefloe/dispatch019.html#v210
%       What you need to know about 10-bit AVI files.
%
    file = fopen(filename, 'r', 'l');
    if file < 0
        error('MATLAB:aviinfoalt', '''%s'' does not exist', filename);
    end
    file_inf            = dir(filename);
    info.Filename       = filename;
    info.FileModDate    = file_inf.date;
    info.FileSize       = file_inf.bytes;
    fpos = 1; % stores the current reading position of data from file

    % format of beginning header in file:
    %   'RIFF' size 'avi  LIST' size 'hdrl avih' size 
    beg_inf = readAndVerify(file, 32, '*uint8');
    fpos = fpos + 4;
%     riff_size = typecast( beg_inf(fpos:fpos+3), 'uint32' );
    fpos = fpos+4;

    if (strcmpi( 'avi ', char(beg_inf(fpos:fpos+3)') ) < 1 )
        error('MATLAB:aviinfoalt', ...
              '''%s'' is not an avi file', info.Filename);
    end
    fpos = fpos+4+4;
    % LIST header contains all header information before the
    % actual movie information
    hdr_end_pos = typecast( beg_inf(fpos:fpos+3), 'uint32' ) ...
                  + fpos-1 + 4;
    fpos = fpos+4+8;

    avi_hdr_size = typecast( beg_inf(fpos:fpos+3), 'uint32' );
%     fpos = fpos+4;
    data = readAndVerify(file, avi_hdr_size, '*uchar');
    
    avi_hdr = readAviHeader( data );
    vids_found = 0;
    auds_found = 0;
% sometimes there might be 2 streams but only one strh LIST, so this
% is a very tricky way to make sure all the strh headers are found
    while vids_found+auds_found < avi_hdr.NumStreams
        stream_size = findlist( file, 'strl' );
        stream_end_pos = ftell(file) + stream_size - 4;
        stream ...
            = readAndVerify(file, stream_end_pos-ftell(file), '*uchar');
        fpos = 1;
        
        % the 'strh' chunk tells us whether this is a header for
        % audio or video and tells us the color encoding if video
        [strh_size, fpos] = findData(stream, fpos, 'strh');
        strh_end_pos = fpos + strh_size;
        stream_type = char( stream(fpos:fpos+3)' );
        fpos = fpos + 4;
%% -----------------------------------------------------------------------
        if ( strcmpi(stream_type, 'vids') )
            vids_found = 1;
            strh = readAudioVideoHeader( stream, fpos );
            info.Codec = strh.Codec;
            info.FramesPerSecond = strh.Rate/strh.Scale;
            fpos = strh_end_pos;
    
            % Some files have a mismatched number of frames in the 
            % MainHeader and VideoStreamHeader.  We should always trust 
            % the VideoStreamHeaders number of frames over the 
            % MainHeader.TotalFrmes. However, there was a bug in 
            % AVIFILE which generates files such that 
            % MainHeader.NumFrames was greater than 
            % VideoStreamHeader's frames. So, to maintain 
            % backward compatibility with AVIFILE generated AVIs only 
            % update the main headers total frames if it is less than 
            % the video stream headers frame count.
            if avi_hdr.NumFrames < strh.Length
               avi_hdr.NumFrames = strh.Length;
            end
            
            % the 'strf' chunk contains information about the
            % planes, bit depth, compression, and color map
            [strf_size, fpos] = findData(stream, fpos, 'strf');
            strf_end_pos = fpos + strf_size;
            strf_hdr = readBitmapHeader(stream, fpos, strf_size);
            fpos = strf_end_pos;
            
            % the 'indx' is either a 'frame index' with offsets and
            % sizes of '00db' chunks or a 'super index' with offsets
            % and sizes to 'frame indexes' throughout the file. This
            % chunk does not always exist.
            if (fpos+3 <= size(stream, 1))
                nextChunk = stream(fpos:fpos+3);
            else
                nextChunk = ' ';
            end
            fpos = fpos + 4;
            if ( strcmpi( char( nextChunk' ), 'indx' ) )
                fpos = fpos + 8;
                num_indexes ...
                    = typecast( stream(fpos:fpos+3), 'uint32' );
                % skip 4 bytes for what was just read and skip '00db' 
                % and empty bytes after it
                fpos = fpos + 4 + 16;
                index_vids = ones(num_indexes, 3); % preallocate
                % This is safe because I believe all 'indx'
                % chunks are super indexes.
                for index_num = 1:num_indexes
                    % assert we aren't overwriting data from other 
                    % streams
                    assert(index_vids(index_num, 1) == 1);
                    % read in offset of index
                    index_vids(index_num, 1) ...
                        = typecast(stream(fpos:fpos+7), 'uint64');
                    fpos = fpos + 8;
                    % read in size of index
                    index_vids(index_num, 2) ...
                        = typecast(stream(fpos:fpos+3), 'uint32');
                    fpos = fpos + 4;
                    % read in number of frames contained in index
                    index_vids(index_num, 3) ...
                        = typecast(stream(fpos:fpos+3), 'uint32');
                    fpos = fpos + 4;
                end
                vidFrames = getvidFrames(file, index_vids, avi_hdr);
            else
            % there is no super index, so we must seek past movi
            % information and find the 'idx1' chunk
                ret = ftell(file);
                fseek(file, hdr_end_pos, -1);
                movi_size = findlist( file, 'movi' );
                header_offset = ftell(file)-4; % -4 for 'movi'
                fseek(file, movi_size-4, 0);
                Itype = readAndVerify(file, 4, '*uchar')';
                if (strcmpi(char(Itype), 'idx1'))
                    index_size = fread(file, 1, 'uint32');
                    index = fread(file, (index_size/4), 'uint32');
                    % idx1 comes in looking like the following:
                    % '00db' or '00dc'
                    % 00 00 00 10 -- I don't know what this is
                    % [offset of frame]
                    % [size of frame]
                    % ... repeat ...
                    index = reshape(index, 4, (index_size/16));

                    % if audio exists, it will be interleaved here
                    % '00db' cast to int == 1650733104
                    % '01wb' cast to int == 1651978544
                    video = index(:, (index(1,:) == 1650733104) | ...
                                     (index(1,:) == 1667510320));
                    audio = index(:, (index(1,:) == 1651978544) | ...
                                     (index(1,:) == 1668755760));
                    vidFrames = video(3:4, :);
                    if (size(audio, 2) > 0)
                        audFrames = audio(3:4, :);
                    end
                    % the offsets in this index may be absolute 
                    % offsets or relative to the header. AVI parsers 
                    % should handle either case
                    fseek(file, vidFrames(1,1), -1);
                    Otype = char(fread(file, 4, 'uchar')');
                    if (~strcmpi(Otype, '00db') && ...
                        ~strcmpi(Otype, '00dc'))
                        vidFrames(1, :) ...
                            = vidFrames(1, :) + header_offset;
                        if (size(audio, 2) > 0)
                            audFrames(1, :) ...
                                = audFrames(1, :) + header_offset;
                        end
                    end
                    vidFrames(1, :) = vidFrames(1, :) + 8;
                    if (size(audio, 2) > 0)
                        audFrames(1, :) = audFrames(1, :) + 8;
                    end
                else
                    % No index was found, so the frames must be
                    % manually located. Issue a warning, so the
                    % user can be aware of the problem.
                    warning('readAvi:index_location', ...
                            'No index was found - reading may be slow');
                    vidFrames = zeros(2, avi_hdr.NumFrames);
                    fseek(file, header_offset+4, -1);
                    frame = 1;
                    while (ftell(file) < movi_size+header_offset);
                        chunk.ckid ...
                            = char( readAndVerify(file, 4, '*uchar')' );
                        chunk.cksize ...
                            = readAndVerify(file, 1, 'uint32');
                        if (strcmpi(chunk.ckid,'00db') || ...
                            strcmpi(chunk.ckid,'00dc'))
                            vidFrames(1, frame) = ftell(file);
                            vidFrames(2, frame) = chunk.cksize;
                            frame = frame + 1;
                        end
                        skipchunk(file,chunk);
                    end
                end
                fseek(file, ret, -1); % return to header positions
            end
%             fpos = fpos + 4;
%% -----------------------------------------------------------------------
        elseif ( strcmpi(stream_type, 'auds') )
            auds_found = 1;
            strh_aud = readAudioVideoHeader(stream, fpos);
            fpos = strh_end_pos;
            [strf_size, fpos] = findData(stream, fpos, 'strf');
            strf_end_pos = fpos + strf_size;
            
            strf_aud = readAudioFormat( stream, fpos );
            fpos = strf_end_pos;
            
            if ~exist('audFrames', 'var')
                % the 'indx' is either a 'frame index' with offsets and
                % sizes of '00db' chunks or a 'super index' with offsets
                % and sizes to 'frame indexes' throughout the file. This
                % chunk does not always exist.
                if (fpos+3 <= size(stream, 1))
                    nextChunk = stream(fpos:fpos+3);
                else
                    nextChunk = ' ';
                end
                fpos = fpos + 4;
                if ( strcmpi( char( nextChunk' ), 'indx' ) )
                    fpos = fpos + 8;
                    num_indexes ...
                        = typecast( stream(fpos:fpos+3), 'uint32' );
                    % skip 4 bytes for what was just read and skip '00db' 
                    % and empty bytes after it
                    fpos = fpos + 4 + 16;
                    index_auds = ones(num_indexes, 3); % preallocate
                    % This is safe because I believe all 'indx'
                    % chunks are super indexes.
                    for index_num = 1:num_indexes
                        % assert we aren't overwriting data from other 
                        % streams
                        assert(index_auds(index_num, 1) == 1);
                        % read in offset of index
                        index_auds(index_num, 1) ...
                            = typecast(stream(fpos:fpos+7), 'uint64');
                        fpos = fpos + 8;
                        % read in size of index
                        index_auds(index_num, 2) ...
                            = typecast(stream(fpos:fpos+3), 'uint32');
                        fpos = fpos + 4;
                        % read in number of frames contained in index
                        index_auds(index_num, 3) ...
                            = typecast(stream(fpos:fpos+3), 'uint32');
                        fpos = fpos + 4;
                    end
                    audFrames = getaudFrames(file, index_auds);
    %                 audFrames = [];
                else
                % there is no super index, so we must seek past movi
                % information and find the 'idx1' chunk
                    ret = ftell(file);
                    fseek(file, hdr_end_pos, -1);
                    movi_size = findlist( file, 'movi' );
                    header_offset = ftell(file)-4; % -4 for 'movi'
                    fseek(file, movi_size-4, 0);
                    Itype = readAndVerify(file, 4, '*uchar')';
                    if (strcmpi(char(Itype), 'idx1'))
                        index_size = fread(file, 1, 'uint32');
                        index = fread(file, (index_size/4), 'uint32');
                        % idx1 comes in looking like the following:
                        % '00db' or '00dc'
                        % 00 00 00 10 -- I don't know what this is
                        % [offset of frame]
                        % [size of frame]
                        % ... repeat ...
                        index = reshape(index, 4, (index_size/16));
                        % just in case the index is interleaved, pick
                        % off all chunks that aren't video chunks.
                        % '01wb' cast to int == 1651978544
                        audio = index(:, (index(1,:) == 1651978544) | ...
                                         (index(1,:) == 1668755760));
                        audFrames = audio(3:4, :);
                        % the offsets in this index may be absolute 
                        % offsets or relative to the header. AVI parsers 
                        % should handle either case
                        fseek(file, audFrames(1,1), -1);
                        Otype = char(fread(file, 4, 'uchar')');
                        if (~strcmpi(Otype, '01wb') && ...
                            ~strcmpi(Otype, '01wc'))
                            audFrames(1, :) ...
                                = audFrames(1, :) + header_offset;
                        end
                        audFrames(1, :) = audFrames(1, :) + 8;
                    else
                        % No index was found, so the frames must be
                        % manually located. Issue a warning, so the
                        % user can be aware of the problem.
                        warning('readAvi:index_location', ...
                                'No index was found - reading may be slow');
                        audFrames = zeros(2, avi_hdr.NumFrames);
                        fseek(file, header_offset+4, -1);
                        frame = 1;
                        while (ftell(file) < movi_size+header_offset);
                            chunk.ckid ...
                                = char( readAndVerify(file, 4, '*uchar')' );
                            chunk.cksize ...
                                = readAndVerify(file, 1, 'uint32');
                            if (strcmpi(chunk.ckid,'01wb') || ...
                                strcmpi(chunk.ckid,'01wc'))
                                audFrames(1, frame) = ftell(file);
                                audFrames(2, frame) = chunk.cksize;
                                frame = frame + 1;
                            end
                            skipchunk(file,chunk);
                        end
                    end
                    fseek(file, ret, -1); % return to header positions
                end
    %             fpos = fpos + 4;
            end
        end
    end
%% prepare output --------------------------------------------------------
    info.NumFrames          = cast(avi_hdr.NumFrames, 'double');
    info.Height             = cast(avi_hdr.Height, 'double');
    info.Width              = cast(avi_hdr.Width, 'double');
    info.ImageType          = strf_hdr.ImageType;
    info.VideoCompression   = strf_hdr.VideoCompression;
    info.Quality            = 0; % TODO
    info.NumColormapEntries = cast(strf_hdr.NumColormapEntries, 'double');
    info.BitDepth           = cast(strf_hdr.BitDepth, 'double');
    % determine the file's color type
    % bytes/pixel possibilities:
    % 3/1  - rgb 24
    % 4/1  - rgb 32
    % 4/2  - uyvy, yuyv
    % 16/6 - uyvy 10-bit
    if strcmpi(info.VideoCompression, 'none')
        if info.BitDepth == 24 || info.BitDepth == 32
            info.ColorType = 'RGB';
        else
            info.ColorType = 'UYVY';
        end
    else
        info.ColorType = 'UYVY';
    end
    
    info.vidFrames    = cast(vidFrames, 'double');
    if exist('strf_aud', 'var')
        info.AudioFormat = strf_aud.Format;
        info.AudioRate = strf_aud.SampleRate;
        info.NumAudioChannels = strf_aud.NumChannels;
        info.BytesPerSec = strf_aud.BytesPerSec;
        info.BlockAlign = strf_aud.BlockAlign;
        info.SampleSize = strh_aud.SampleSize;
        info.BufferSize = strh_aud.BufferSize;
        info.BitsPerSample = 8*ceil(info.BlockAlign/info.NumAudioChannels);
        info.audFrames = audFrames;
        if(isfield(strf_aud,'SubFormat'))
            info.SubFormat = strf_aud.SubFormat;
        end
            
    end
    
    fclose(file);
return ;

%% -----------------------------------------------------------------------
function avi_hdr = readAviHeader( data )
% Reads an 'avih' header
% Input: The header information read in from file

    fpos = 1;
    fpos = fpos+4; % skip microseconds per frame
    avi_hdr.MaxBytePerSec ...
        = double(typecast( data(fpos:fpos+3), 'uint32' ));
    fpos = fpos+8; % skip reserved
    
    flags =  typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos+4;
    flagbits = find( bitget( flags, 1:32 ) );
    for i = 1:length(flagbits)
      switch flagbits(i)
       case 5
        avi_hdr.HasIndex = 'True';
       case 6
        avi_hdr.MustUseIndex = 'True';
       case 9
        avi_hdr.IsInterleaved = 'True';
       case 12
        avi_hdr.TrustCKType = 'True';
       case 17
        avi_hdr.WasCaptureFile = 'True';
       case 18
        avi_hdr.Copywrited = 'True';
      end
    end

    avi_hdr.NumFrames = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos+8; % skip Initial frames
    avi_hdr.NumStreams = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos+8; % skip Suggested Buffer Size
    avi_hdr.Width = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos+4;
    % Height may be negative if AVI is written top down
    avi_hdr.Height ...
        = typecast(abs( ...
          typecast( data(fpos:fpos+3), 'int32' ) ), 'uint32' );
    fpos = fpos+4;
    avi_hdr.Scale = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos+4;
    avi_hdr.Rate = typecast( data(fpos:fpos+3), 'uint32' );
%     fpos = fpos+4;
    % skip start and length
return ;

%% -----------------------------------------------------------------------
function strh = readAudioVideoHeader( stream, fpos )
% reads the STRH chunk information. this can either contain video
% or audio information

    strh.Codec = char( stream(fpos:fpos+3)' );
    fpos = fpos + 4 + 12; % skip flags, reserved, initial frames

    strh.Scale = double(typecast(stream(fpos:fpos+3), 'uint32'));
    fpos = fpos + 4;
    
    strh.Rate = double(typecast(stream(fpos:fpos+3), 'uint32'));
    fpos = fpos + 4 + 4; % skip start
    
    strh.Length = double(typecast(stream(fpos:fpos+3), 'uint32'));
    fpos = fpos + 4;
    
    strh.BufferSize = double(typecast(stream(fpos:fpos+3), 'uint32'));
    fpos = fpos + 4 + 4; % skip quality (it is unreliable)
    
    strh.SampleSize = double(typecast(stream(fpos:fpos+3), 'uint32'));
return ;

%% -----------------------------------------------------------------------
function strf = readBitmapHeader(data, fpos, strf_size)
% Reads the BITMAPINFO header information.

    strf.BitmapHeaderSize = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos + 4;
    strf.Width = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos + 4;
    strf.Height = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos + 4;
    strf.Planes = typecast( data(fpos:fpos+1), 'uint16' );
    fpos = fpos + 2;
    strf.BitDepth = typecast( data(fpos:fpos+1), 'uint16' );
    fpos = fpos + 2;

    % Read Compression.
    compress = typecast( data(fpos:fpos+3), 'uint32' );
    switch compress
    case 0
        compression = 'none';
    case 1
        compression = '8-bit RLE';
    case 2
        compression = '4-bit RLE';
    case 3
        compression = 'bitfields';
    otherwise
        compression = '';
    end
    if isempty(compression)
        % This code worked for older MATLAB
%         code = [char(bitshift(compress,0,'uint8')) ...
%                 char(bitshift(compress,-8,'uint8')) ...
%                 char(bitshift(compress,-16,'uint8')) ...
%                 char(bitshift(compress,-24,'uint8'))];
        code = char(typecast(compress,'uint8'));
        switch lower(code)
        case 'none'
            compression = 'None';
        case 'rgb '
            compression = 'None';
        case 'raw '
            compression = 'None';  
        case '    '
            compression = 'None';
        case 'rle '
            compression = 'RLE';
        case 'cvid'
            compression = 'Cinepak';
        case 'iv32'
            compression = 'Indeo3';
        case 'iv50'
            compression = 'Indeo5';
        case 'msvc'
            compression = 'MSVC';
        case 'cram'
            compression = 'MSVC';
        otherwise
            compression = code;
        end
    end
    fpos = fpos + 4;
    strf.VideoCompression = compression;
    
    strf.Bitmapsize = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos + 4;
    strf.HorzResoltion = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos + 4;
    strf.VertResolution = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos + 4;
    strf.NumColorsUsed = typecast( data(fpos:fpos+3), 'uint32' );
    fpos = fpos + 4;
    strf.NumImportantColors = typecast( data(fpos:fpos+3), 'uint32' );
%     fpos = fpos + 4;
    strf.NumColormapEntries = ...
        (strf_size - strf.BitmapHeaderSize)/4;
    % 8-bit grayscale
    % 24-bit truecolor
    % 8-bit indexed
    if strf.NumColorsUsed > 0
        strf.ImageType = 'indexed';
    else
        if strf.BitDepth > 8
            strf.ImageType = 'truecolor';
            strf.ImageType = 'truecolor';
        else
            strf.ImageType = 'grayscale';
        end
    end
return ;

%% -----------------------------------------------------------------------
function strf = readAudioFormat( data, fpos )
% Read WAV format chunk information.

    % Read format tag.
    formatTag = typecast( data(fpos:fpos+1), 'uint16' );
    fpos = fpos + 2;

    % Complete list of formats can be found in Microsoft Platform SDK
    % header file "MMReg.h" or in MSDN Library (search for "registered 
    % wave formats").
    switch formatTag
     case  1
      strf.Format = 'PCM';
     case 2
      strf.Format = 'Microsoft ADPCM';
     case 6
      strf.Format = 'CCITT a-law';
     case 7
      strf.Format = 'CCITT mu-law';
     case 17
      strf.Format = 'IMA ADPCM';
     case 34
      strf.Format = 'DSP Group TrueSpeech TM';
     case 49
      strf.Format = 'GSM 6.10';
     case 50
      strf.Format = 'MSN Audio';
     otherwise
      strf.Format = ['Format # 0x' dec2hex(formatTag)];
    end

    % Read number of channels.
    strf.NumChannels = double(typecast( data(fpos:fpos+1), 'uint16'));
    fpos = fpos + 2;

    % Read samples per second.
    strf.SampleRate = double(typecast( data(fpos:fpos+3), 'uint32'));
    fpos = fpos + 4;

    % Read buffer estimation.
    strf.BytesPerSec = double(typecast( data(fpos:fpos+3), 'uint32'));
    fpos = fpos + 4;
    
    % Read block size of data.
    strf.BlockAlign = double(typecast( data(fpos:fpos+1), 'uint16'));
%     fpos = fpos + 2;

%MY EDIT - Information gathered from 
%       http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html
    if(formatTag == 65534)
        %The following section only needs to be added for clips that are of
        %format fffe (WAVE_FORMAT_EXTENSIBLE).  Otherwise, this information
        %does not exist.
        fpos = fpos + 2;
        %Bits per sample
        %     test = double(typecast( data(fpos:fpos+1),'uint16'));
        
        fpos = fpos + 2;
        %Size of extension (cbSize)
        %     test1 = double(typecast( data(fpos:fpos+1),'uint16'));
        
        fpos = fpos + 2;
        %Valid Bits Per Sample
%         strf.ValidBitsPerSample = double(typecast( data(fpos:fpos+1),'uint16'));
        
        fpos = fpos + 2;
        %dwChannelMask (Speaker position mask)
%         strf.SpeakerPos = double(typecast( data(fpos:fpos+3),'uint32'));
        %Quadraphonic = 0x33 = 00110011
        %Positioning is the following:
        %
        % Back Right, Back Left, Low Freq, Front Center, Front Right, Front
        % Left.
        %
        % 5.1 = 63 (decimal => to hex =>  3F => to binary => 00111111
        
        fpos = fpos + 4;
        %SubFormat (GUID (first tow bytes are the data format code))  As of
        %right now, only the first byte is important to use.  This will allow
        %us to tell if audio that is greater than 2 channels has 32 bit audio
        %or 32 bit floating point audio.  If the response is 1, then its just
        %32 bit audio (Basically it just is PCM).  If the response is 3, then
        %its 32 bit floating point audio (IEEE floating point).  GUID,
        %SubFormat, is 16 bytes long.  This function is only taking the first
        %bit.  If needed at a later time, this can be modified to include all
        %16 bytes.
        strf.SubFormat = double(typecast( data(fpos),'uint8'));
        %     test2 = double(typecast( data(fpos:fpos+15),'uint64'));
    end
    
return

%% -----------------------------------------------------------------------
function [size, pos] = findData(data, fpos, target)
% Finds a chunk in the data read from file. MAKE SURE the chunk is
% in the data being passed.
% This is quite similar to "findchunk". The only difference is that
% the data is read from the file and then searched.

    chunk.ckid      = '    ';
    chunk.cksize    = 0;

    while( strcmpi( chunk.ckid, target ) == 0 )
        % if the size is odd, it requires a pad byte
        pad = rem(chunk.cksize, 2); 
        % seek past current chunk
        fpos = fpos + chunk.cksize + pad;
        
        chunk.ckid = char( data( fpos:fpos+3 )' );
        fpos = fpos + 4;
        chunk.cksize = typecast( data(fpos:fpos+3), 'uint32' );
        fpos = fpos + 4;
    end
    size = chunk.cksize;
    pos = fpos;
return ;

%% -----------------------------------------------------------------------
function [frame_list] = getvidFrames( file, index_vids, avi_hdr )
% read data from sub indexes throughout file
% This function is safe because if the file has more than 1 RIFF
% chunk, this function won't be called...theoretically.

    ix_data     = ones( size(index_vids, 1), max(index_vids(:,2))/4 );
    frame_list  = ones(2, avi_hdr.NumFrames);
    framesIn    = 1;
    file_pos    = ftell(file);
    % for each video stream, read in positions of frames
    for index_num = 1:size(index_vids, 1)
        % seek to position of sub-index and read data
        fseek(file, index_vids(index_num, 1)+8, -1);
        num_vals = (index_vids(index_num, 2)-8)/4;

        ix_data(index_num, 1:num_vals) ...
            = readAndVerify(file, num_vals, '*uint32');
        fpos = 1 + 3;
        
        % the '00ix' chunk is formatted as such 'offset size offset
        % size ... '. the offsets represent the distance from the 
        % beginning of their parent RIFF chunk which may also have an
        % offset from the beginning of the file which is read here
        temp = uint32(ix_data(index_num, fpos:fpos+1));
        riff_offset = double(typecast(temp, 'uint64')); % ...wow
            
        fpos = fpos + 3;
        frame_list(:,framesIn:(index_vids(index_num, 3)+framesIn-1))...
            = reshape( ix_data(index_num, ...
                       fpos:(index_vids(index_num, 3)*2+fpos-1)), ...
                       2, index_vids(index_num, 3));
        % account for RIFF offset
        frame_list(1,framesIn:(index_vids(index_num, 3)+framesIn-1))...
            = frame_list(1,...
            framesIn:(index_vids(index_num, 3)+framesIn-1))...
            + riff_offset;
        % in case you weren't following. frames now looks like this:
        %   offset  offset  offset  offset  ...
        %   size    size    size    size    ...
        % nifty right? And the offsets are absolute (from beginning
        % of file)
        framesIn = framesIn + index_vids(index_num, 3);
    end
    % seek back to original position before function call
    fseek(file, file_pos, -1);
return ;

%% -----------------------------------------------------------------------
function [frame_list] = getaudFrames( file, index_auds )
% read data from sub indexes throughout file
% This function is safe because if the file has more than 1 RIFF
% chunk, this function won't be called...theoretically.
%
% TODO: This function is dreadfully similar to getvidFrames. You could
%       easily call this function in place of "getvidFrames" because
%       the end result is the same. The only reason I don't rush to do
%       that is because "getvidFrames" is more efficient because it
%       preallocates. Something could be done in the future, however.

    file_pos    = ftell(file);
    frame_list  = [];
    % for each video stream, read in positions of frames
    for index_num = 1:size(index_auds, 1)
        % seek to position of sub-index and read data
        fseek(file, index_auds(index_num, 1)+8, -1);
        num_vals = (index_auds(index_num, 2)-8)/4;
        
        ix_data = readAndVerify(file, num_vals, '*uint32');
        fpos = 1 + 3;
        
        % the '00ix' chunk is formatted as such 'offset size offset
        % size ... '. the offsets represent the distance from the 
        % beginning of their parent RIFF chunk which may also have an
        % offset from the beginning of the file which is read here
        tmp = uint32(ix_data(fpos:fpos+1));
        riff_offset = double(typecast(tmp, 'uint64')); % ...wow
        fpos = fpos + 3;
        
        tmp = double(reshape(ix_data(fpos:size(ix_data)), 2, []));
        tmp(1, :) = tmp(1, :) + riff_offset;
        % we cannot preallocate since we don't know the size
        frame_list = [frame_list, tmp]; %#ok<AGROW>
    end
    % seek back to original position before function call
    fseek(file, file_pos, -1);
return ;

%% -----------------------------------------------------------------------
function size = findlist(fid,listtype)
% Finds a list in the given file

    found = -1;
    size = -1;
    while(found == -1)
        [chunk,~,~] = findchunk(fid,'LIST');
        checktype = fread(fid, 4, '*uchar')';
        if (checktype == listtype) %#ok<BDSCI>
            size = chunk.cksize;
            break;
        else
            fseek(fid,-4,0); %Go back so we can skip the LIST
            skipchunk(fid,chunk);
        end
        if ( feof(fid) )
            return ;
        end
    end
return ;

%% -----------------------------------------------------------------------
function data = readAndVerify( file, num, datatype )
% Reads data from the specified file
    [data, count] = fread(file, num, datatype);
    % count how many elements were actually requested
%    num = sum(sum(sum(num > 0 | num < 1)));
    assert( eq( count, num) );
return ;

%% -----------------------------------------------------------------------
function [chunk,msg,msgID] = findchunk(fid,chunktype)
%FINDCHUNK find chunk in AVI
%   [CHUNK,MSG,msgID] = FINDCHUNK(FID,CHUNKTYPE) finds a chunk of type 
%   CHUNKTYPE in the AVI file represented by FID.  CHUNK is a structure 
%   with fields 'ckid' and 'cksize' representing the chunk ID and chunk 
%   size respectively.  Unknown chunks are ignored (skipped). 

%   Copyright 1984-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2007/07/26 19:30:47 $

    chunk.ckid = '';
    chunk.cksize = 0;
    msg = '';
    msgID='';

    while( strcmp(chunk.ckid,chunktype) == 0 )
      [msg msgID] = skipchunk(fid,chunk);
      if ~isempty(msg)
        fclose(fid);
        error(msgID,msg);
      end
      [id, count] = fread(fid,4,'uchar');
      chunk.ckid = char(id)';
      if (count ~= 4 )
        msg = sprintf('''%s'' did not appear as expected.',chunktype);
        msgID = 'MATLAB:findchunk:unexpectedChunkType';
      end
      [chunk.cksize, count] = fread(fid,1,'uint32');
      if (count ~= 1)
        msg = sprintf('''%s'' did not appear as expected.',chunktype);
        msgID = 'MATLAB:findchunk:unexpectedChunkType';
      end
      if ( ~isempty(msg) ), return; end
    end
return ;

%% -----------------------------------------------------------------------
function [msg msgID] = skipchunk(fid,chunk)
%SKIPCHUNK skip chunk in AVI
%   [MSG MSGID] = SKIPCHUNK(FID,CHUNK) skips CHUNK.cksize bytes in the 
%   AVI file FID.  MSG contains an error message string if the skip 
%   fails, otherwise it is an empty string.

%   Copyright 1984-2007 The MathWorks, Inc.
%   $Revision: 1.1.6.4 $  $Date: 2007/07/26 19:31:04 $

    msg = '';
    msgID = '';
    % Determine if pad byte is necessary; % If the chunk size is odd, 
    % there is a pad byte
    if ( rem(chunk.cksize,2) ) 
      pad = 1;
    else 
      pad = 0;
    end

    % Skip the chunk
    status = fseek(fid,chunk.cksize + pad,0);
    if ( status == -1 )
      msg = 'Incorrect chunk size information in AVI file.';
      msgID = 'MATLAB:skipChunk:incorrectChunkSize';
    end
return;







%% -----------------------------------------------------------------------
% THIS IS AN ALTERNATE IMPLEMENTATION OF THE 10-BIT READ FUNCTION.
% TO USE IT, SIMPLY UNCOMMENT THE LINES BELOW AND COMMENT-OUT THE
% CURRENT FUNCTION. IT IS SLOWER THAN THE CURRENT VERSION, BUT THERE
% MIGHT BE A WAY TO SPEED IT UP.
% % ----------------------------------------------------------------------
% function [y,cb,cr] = read_10bit_uyvy(fid, is_whole_image, sroi, ...
%                                      is_interp, num_rows, num_cols, sz)
% % read one YCbCr frame from 10-bit data
% % NOTE: Look at the following site for explanation:
% % http://developer.apple.com/quicktime/icefloe/dispatch019.html#v210
%
%     global data;
%     % read in image
%     data = readAndCheck(fid, [4, sz/16], '*uint32');
%     % preallocate - ZEROS and NOT ONES is VERY important here I
%     % think...but maybe it doesn't matter
%      y = zeros([1,num_rows*num_cols], 'uint16');
%     cb = zeros([1,num_cols*num_rows/2], 'uint16');
%     cr = cb;
%
%     % Picture of what the bytes look like coming in: 1 char = 1 bit
%     %   ///-CB-/// ////-Y-/// ///-CR-/// XX     - 1st 32 bits
%     %   ////-Y-/// ///-CB-/// ////-Y-/// XX     - 2nd 32 bits
%     %   ///-CR-/// ////-Y-/// ///-CB-/// XX     - 3rd 32 bits
%     %   ////-Y-/// ///-CR-/// ////-Y-/// XX     - 4th 32 bits
%
%     sz = num_cols*num_rows;
%     % in every 4x4 byte matrix, there are 6 y values that need to
%     % be extracted
%     y  = read10( y, 1, 6, sz, 1, 11:20);
%     y  = read10( y, 2, 6, sz, 2,  1:10);
%     y  = read10( y, 3, 6, sz, 2, 21:30);
%     y  = read10( y, 4, 6, sz, 3, 11:20);
%     y  = read10( y, 5, 6, sz, 4,  1:10);
%     y  = read10( y, 6, 6, sz, 4, 21:30);
%
%     sz = sz/2;
%     % in every 4x4 byte matrix, there are 3 cb and cr values that
%     % need to be extracted
%     cb = read10(cb, 1, 3, sz, 1,  1:10);
%     cb = read10(cb, 2, 3, sz, 2, 11:20);
%     cb = read10(cb, 3, 3, sz, 3, 21:30);
%
%     cr = read10(cr, 1, 3, sz, 1, 21:30);
%     cr = read10(cr, 2, 3, sz, 3,  1:10);
%     cr = read10(cr, 3, 3, sz, 4, 11:20);
%
%     % because this is 10-bit data, the bits need to be shifted right
%     % 2 places to turn it into 8-bit data.
%     y  = single(y)/4;
%     cb = single(cb)/4;
%     cr = single(cr)/4;
%
%     % reshape the extracted information
%     y = reshape(y, num_cols, num_rows)';
%
%     cb = reshape(cb,num_cols/2,num_rows)';
%     cb = [cb ; cb];
%     cb = reshape(cb,num_rows,num_cols);
%
%     cr = reshape(cr,num_cols/2,num_rows)';
%     cr = [cr ; cr];
%     cr = reshape(cr,num_rows,num_cols);
%
%     % Interpolate, if requested
%     if is_interp == 1,
%         for i=2:2:num_cols-2,
%             % Bug fix 3/16/09
%             cb(:,i) = (cb(:,i-1) + cb(:,i+1))/2;
%             % Bug fix 3/16/09
%             cr(:,i) = (cr(:,i-1) + cr(:,i+1))/2;
%         end
%     end
%
%     if ~is_whole_image,
%         y = y(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
%         if nargout == 3,
%             cb = cb(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
%             cr = cr(sroi.top:sroi.bottom, sroi.left:sroi.right, :);
%         end
%     end
% return ;
%
% function ret = read10( V, vp, st, sz, dp, bi )
% % This function serves a VERY specific purpose. It reads the given
% % 10 bits from the global data and sets those bits in the y, cb, or
% % cr matrix that is given by V. Honestly, it is best if you don't
% % try to understand it, ha ha.
%     global data;
%     try
%         V(vp:st:sz) = bitset(V(vp:st:sz), 1, bitget(data(dp,:), bi(1)));
%         V(vp:st:sz) = bitset(V(vp:st:sz), 2, bitget(data(dp,:), bi(2)));
%         V(vp:st:sz) = bitset(V(vp:st:sz), 3, bitget(data(dp,:), bi(3)));
%         V(vp:st:sz) = bitset(V(vp:st:sz), 4, bitget(data(dp,:), bi(4)));
%         V(vp:st:sz) = bitset(V(vp:st:sz), 5, bitget(data(dp,:), bi(5)));
%         V(vp:st:sz) = bitset(V(vp:st:sz), 6, bitget(data(dp,:), bi(6)));
%         V(vp:st:sz) = bitset(V(vp:st:sz), 7, bitget(data(dp,:), bi(7)));
%         V(vp:st:sz) = bitset(V(vp:st:sz), 8, bitget(data(dp,:), bi(8)));
%         V(vp:st:sz) = bitset(V(vp:st:sz), 9, bitget(data(dp,:), bi(9)));
%         V(vp:st:sz) = bitset(V(vp:st:sz),10, bitget(data(dp,:), bi(10)));
%     catch e
%         % there have been some 10-bit videos made by VirtualDub that
%         % are unlike any 10-bit format I've seen.  There should be 6
%         % pixels for every 4 bytes, but these videos have more bytes
%         % than expected.
%         disp([e.message ' - Corrupted 10-bit file']);
%     end
%
%     ret = V;
% return ;
