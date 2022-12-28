function [] = write_avi(colorIn, c1, c2, c3, colorOut, ...
                        avi_name, fps, varargin)
% DESCRIPTION:
% This function takes the RGB or YCbCr color components of a video and
% writes them to an AVI file in either YCbCr or RGB color format. It
% can also except audio data to write out.
%
% SYNTAX:
% write_avi(colorIn, c1, c2, c3, colorOut, newFile, fps)
% write_avi(..., 'PropertyName', ...)
% write_avi(..., 'PropertyName', PropertyValue, ...)
%
% DESCRIPTION:
% write_avi(colorIn, c1, c2, c3, colorOut, aviFileName, fps) >
%   writes the given data to an AVI file with the given file name and
%   frames per second.
% write_avi(colorIn, c1, c2, c3, colorOut, aviFileName, fps, 10) >
%   writes the given data to an AVI file in 10-bit format with the 
%   given file name and frames per second.
%
% INPUT ARGUMENTS:
% colorIn   A string, describing the colorspace of the data being passed
%           to this function. Specify in one of the following forms:
%               'YCbCr'     - YCbCr colorspace
%               'RGB'       - RGB colorspace
%
% c1, c2, c3    Three matrices with the data to write to the avi file.
%               They must correspond to the colorIn parameter, so they
%               must be y, cb, and cr for 'YCbCr' and r, g, and b for
%               'RGB'. Also, the values must range from [0..255.75].
%
% colorOut  A string, describing the colorspace to write to the AVI
%           file. Specify in one of the following forms:
%               'YCbCr'     - YCbCr colorspace, 4:2:2
%               'RGB'       - RGB colorspace
%               'YV12'      - YCbCr colorspace, 4:2:0, coded in YV12 format.
%                             To compress the cb and cr components, a
%                             distributed average is taken.
%
% aviFileName   A string with the name of the file to be written out.
%
% fps   The video's frames per second. 30000/1001 is common.
%
% OPTIONAL INPUT ARGUMENTS
%
% '10'        Write 10-bit data out to the AVI file. This option is only
%           compatable with colorOut='YCbCr'.  By default, 8-bit data saved. 
%           Note that this is an integer (10) and not a string.
%
% '128'     Add 128 to input Cb and Cr values. Thus, shift Cb and Cr from the
%           [-128..127] range to [0..255]. By default, Cb and Cr values
%           are assumed to be in the [0..255] range already.
%
% 'audio'   A string indicating audio is to be written to the AVI file,
%           as well. This option should be succeeded by the following
%           arguments in order:
%
%           audio           - The raw audio data to be written out
%                             contained in a NSamples-by-NChannels matrix.
%                             The values are assumed to be in the range
%                             of -1.0 <= y <= 1.0
%           audioRate       - The sample frequency
%           bitsPerSample   - The desired number of bits per audio sample.
%                             Standard values are 8 and 16
%
% 'subsampled'
%           Only available when colorIn = 'YCbCr' and colorOut = 'YV12'
%           C2 (Cb) and C3 (Cr) are already sub-sampled (i.e., half the
%           horizontal and vertical size of C1 (Y).
%
% 'vd'      A string identifier to indicate that the VirtualDub conversion
%           from 10-bit to 8-bit method be used. The VirtualDub method 
%           is [round((255/255.75)*y)] for the Y plane and is 
%           [floor(cb), floor(cr)] for the Cb and Cr planes. This option 
%           is only for converting 10-bit YCbCr data to 8-bit YCbCr data.
%           
%
% OUTPUT ARGUMENTS: (none)
%
% EXAMPLES:
% Write out an 8-bit AVI file in RGB%   
%   % write data out to separate AVI file, named 'new_file.avi', and in
%   % the RGB colorspace
%   % read data from AVI file
%   [y, cb, cr] = read_avi('YCbCr', 'my_file.avi', 'frames', 1, 100);
%   write_avi('YCbCr', y, cb, cr, 'RGB', 'new_file.avi', 29.97);
%
% Write out a 10-bit AVI file in YCbCr
%   % read 8-bit data from AVI file
%   [y, cb, cr] = read_avi('YCbCr', 'my_file.avi', 'frames', 1, 100);
%
%   % write data out to separate AVI file in 10 bits
%   write_avi('YCbCr', y, cb, cr, 'YCbCr', 'new_file.avi', 29.97, 10);
%
% Read in 10-bit data and write out 8-bit data with VDub conversion
%   % read in 10-bit data from file
%   [y, cb, cr] = read_avi('YCbCr', 'file10bit.avi', 'frames', 1, 100);
%
%   % write data to file in 8-bit format with VDub conversion
%   write_avi('YCbCr', y, cb, cr, 'YCbCr', 'file.avi', 29.97, 8, 'vd');
%
% Combine the audio from a wav file with the video from an avi file
%   % read in video data from avi file
%   [y, cb, cr] = read_avi('YCbCr', 'video.avi', 'frames', 1, 100);
%   % read in audio with wavread
%   [aud, Fs, nbits] = wavread('audio.wav');
%
%   % merge audio and video with write_avi
%   write_avi('YCbCr', y, cb, cr, 'YCbCr', 'merged.avi', 29.97, ...
%             'audio', aud, Fs, nbits);
% 
% video globals
global FPS_
global NUM_FRAMES_
global WIDTH_
global HEIGHT_
global FILESIZE_    % not exact file size! only a rough estimate!
global FRM_SIZE_OUT_
global COLOR_
global CODEC_
% audio globals
global AUDIO_RATE_
global AUDIO_NBITS_
global BUFFER_SIZE_
global SAMPLE_SIZE_
global NUM_CHANNELS_
global which_32_bit
% general globals
global RIFF_LIMIT_

FPS_            = fps;
NUM_FRAMES_     = size(c1, 3);
WIDTH_          = size(c1, 2);
HEIGHT_         = size(c1, 1);
CODEC_          = '    ';

AUDIO_RATE_     = 0;
AUDIO_NBITS_    = 0;
BUFFER_SIZE_    = 0;
SAMPLE_SIZE_    = 0;
NUM_CHANNELS_   = 0;

% this controls how much data the program will attempt to put inside
% each RIFF chunk. The limit should be roughly within the bounds of
%               2^31 >= RIFF_LIMIT_ + 4500 >= FrameSize
% Note that bigger is better because problems have come up with
% multi-riff files.
%RIFF_LIMIT_     = 2000000000; %OLD
RIFF_LIMIT_     = 200000000;

vdub            = 0;
shift128        = 0;
bitOut          = 8;
audio           = [];
subsampled      = 0;

% parse incoming color information
if ~strcmpi(colorIn, 'YCbCr') && ~strcmpi(colorIn, 'RGB')
    error('writeavi:colorIncorrect', ...
        'Color IN should be either YCbCr or RGB');
end
% parse outgoing color information
if strcmpi(colorOut, 'YCbCr')
    mult = 2;
    COLOR_ = 'UYVY';
    CODEC_ = 'UYVY'; % this may change later
elseif strcmpi(colorOut, 'RGB')
    mult = 3;
    COLOR_ = '    ';
elseif strcmpi(colorOut, 'YV12')
    mult   = 6/4;
    COLOR_ = 'UYVY';
    CODEC_ = 'YV12';
else
    error('writeavi:colorIncorrect', ...
        'Color OUT should be either YCbCr or RGB');
end

cnt = 1;
% parse arguments
while cnt <= length(varargin)
    if strcmpi(varargin{cnt}, '10')
        % we need to write out 10-bit data if UYVY
        if strcmpi(COLOR_, 'UYVY') && ~strcmpi(CODEC_, 'YV12')
            % clip the data
            c1 = min(c1, 255.75); c1 = max(c1, 0);
            c2 = min(c2, 255.75); c2 = max(c2, 0);
            c3 = min(c3, 255.75); c3 = max(c3, 0);
            % multiply by 4 to get 10-bit data
            c1 = c1*4;
            c2 = c2*4;
            c3 = c3*4;
            CODEC_ = 'v210';
            mult = 16/6;
            bitOut = 10;
        else
            error('MATLAB:write_avi', ...
                '10-bit incompatable with RGB and YV12');
        end
        cnt = cnt + 1;
    elseif strcmpi(varargin{cnt}, 'vd')
        vdub = 1;
        cnt = cnt + 1;
    elseif strcmpi(varargin{cnt}, '128')
        if ~strcmpi(colorIn,'YCbCr'),
            error('MATLAB:write_avi', ...
                '''128'' option only available when colorIn is the YCbCr colorspace');
        end
        shift128 = 1;
        cnt = cnt + 1;
    elseif strcmpi(varargin{cnt}, 'audio')
%         warning('MATLAB:write_avi', ...
%             'Audio write contains a known defect. Written audio is shifted by two audio samples for files longer than 2GB. Bug is caused by multiple RIFFs.');
        audio           = varargin{cnt+1};
        AUDIO_RATE_     = varargin{cnt+2};
        AUDIO_NBITS_    = varargin{cnt+3};
        if(AUDIO_NBITS_ == 32)
            try
                which_32_bit = AUDIO_RATE_(1,2); 
                AUDIO_RATE_ = AUDIO_RATE_(1,1);
            catch
                %Do nothing since AUDIO_RATE_ does not contain two values.
                %This means that the function to read the file was not ITS
                %read_avi.  Therefore, we do not want to crash the program.
                %However, we do need to set the global variable
                %"which_32_bit" to zero for use later in the program.
                which_32_bit = 0;
            end
        else
            %If its not 32 bit audio, then which_32_bit is set to 0.
            which_32_bit = 0;
        end
        BUFFER_SIZE_    = numel(audio)*(AUDIO_NBITS_/8);
        NUM_CHANNELS_   = size(audio, 2);
        SAMPLE_SIZE_    = NUM_CHANNELS_ * AUDIO_NBITS_/8;
        cnt = cnt + 4;
    elseif strcmpi(varargin{cnt}, 'subsampled')
        if strcmpi(colorIn,'YCbCr') && strcmpi(colorOut,'YV12'),
            [x1,y1,z1]=size(c1);
            [x2,y2,z2]=size(c2);
            [x3,y3,z3]=size(c3);
            if x1 ~= 2*x2 || x1 ~= 2*x3 || y1 ~= 2*y2 || y1 ~= 2*y3 || ...
                    z1 ~= z2 || z1 ~= z3
                error('MATLAB:write_avi', ...
                    'Size of color planes C1 (Y), C2 (Cb) and C3 (Cr) do not match 4:2:0 expectations');
            else
                subsampled = 1;
                cnt = cnt + 1;
            end
        else
            error('MATLAB:write_avi', ...
                '''subsampled'' option only available when colorIn is ''YCbCr'' and colorOut is ''YV12''');
        end
    else
        error('MATLAB:write_avi', 'Unexpected parameter type');
    end
end

% if '128' requested, shift the input data now
if shift128,
    c2 = c2 + 128;
    c3 = c3 + 128;
end

% if 8-bit data is being written, it needs to be rounded
if bitOut == 8
    if vdub == 1
        % Use the VirtualDub conversion from 10-bit to 8-bit method: 
        % [round((255/255.75)*y)] for the Y plane,
        % and [floor(cb), floor(cr)] for the Cb and Cr planes. 
        c1 = round((255/255.75)*c1);
    else
        c1 = floor(c1);
    end
    c2 = floor(c2);
    c3 = floor(c3);
    % clip the data
    c1 = min(c1, 255); c1 = max(c1, 0);
    c2 = min(c2, 255); c2 = max(c2, 0);
    c3 = min(c3, 255); c3 = max(c3, 0);
end

FRM_SIZE_OUT_   = ceil(WIDTH_*HEIGHT_*mult);
FILESIZE_       = FRM_SIZE_OUT_*NUM_FRAMES_;

% open avi file for writing.
fout = fopen(avi_name, 'w');
if fout < 0; error('write_avi:file', 'file open failed'); end;

% write out all the header information
[hdrl, ix_vid, ix_aud] = fillHDRL();
ix_vid = ix_vid + 20;
ix_aud = ix_aud + 20;
hdrl = cast(hdrl, 'uint8');
fwrite( fout, 'RIFFccccAVI LIST', 'uchar' );
riff_size = 4;
fwrite( fout, numel(hdrl), 'uint32' );
fwrite( fout, hdrl, 'uchar' );

% begin writing the frames to each riff.
riff_num = 1;
totFrames   = [];
numFrames   = 0;
frames_read = 0;
% while we haven't reached the end of the input data
while frames_read < NUM_FRAMES_
    % we don't know how many frames will be in each riff, but we can
    % estimate.
    frameEst = floor( RIFF_LIMIT_ / FRM_SIZE_OUT_ ) - 1;
    if ((frameEst + frames_read) > NUM_FRAMES_)
        frameEst = NUM_FRAMES_ - frames_read;
    end
    vidFrames = ones(4, frameEst);
    if (riff_num > 1)
        fwrite(fout, 'RIFFccccAVIX', 'uchar');
        riff_size = ftell(fout)-8;
        numFrames = cat(2, numFrames, [riff_size-4; 0]);
    end
    fwrite(fout, 'LISTccccmovi', 'uchar');
    movi_size = ftell(fout)-8;
    frame_num = 1;
    
    % while we haven't reached the end of the data and haven't
    % reached the end of the riff. Because the size of a riff
    % is stored in only 4 bytes, it can't be too big
    while ( ftell(fout) < (riff_num*RIFF_LIMIT_) && ...
            frames_read+frame_num <= NUM_FRAMES_ )
        % read one frame
        a = c1(:,:,frames_read+frame_num);
        b = c2(:,:,frames_read+frame_num);
        c = c3(:,:,frames_read+frame_num);
        
        % prepare input to fit the output
        if strcmpi(colorIn, 'YCbCr') && strcmpi(colorOut, 'RGB')
            [a, b, c] = ycbcr2rgb_double(single(a),...
                single(b),...
                single(c));
        end
        if strcmpi(colorIn, 'RGB') && (strcmpi(colorOut, 'YCbCr') ...
                ||  strcmpi(colorOut, 'YV12'));
            [a, b, c] = rgb2ycbcr_double(a,b,c);
        end
        % prepare the output
        if strcmpi(colorOut, 'YCbCr')
            frame_data = zeros(HEIGHT_,WIDTH_);
            %  Subsample cb and cr by 2 and stuff into array
            frame_data(:,1:2:WIDTH_) = b(:,1:2:WIDTH_);
            frame_data(:,2:2:WIDTH_) = c(:,1:2:WIDTH_);
            %  Merge the y and frame_data arrays
            a = a';
            frame_data = frame_data';
            merge = ...
                cat(1, reshape(frame_data,1,WIDTH_,HEIGHT_), ...
                reshape(a,1,WIDTH_,HEIGHT_));
            merge = reshape(merge,2*WIDTH_,HEIGHT_);
            % the cb and cr color components are only 1/4 the size
            % of the y component in YV12. To cut the size down,
            % this code takes an average of every 2x2 block of
            % pixels and adds that to the cb and cr matrices.
        elseif strcmpi(colorOut, 'YV12')
            if subsampled
                cb = b;
                cr = c;
            else
                cb = reshape( b, 2, HEIGHT_/2, WIDTH_);
                cb = permute( cb, [1, 3, 2] );
                cb = reshape( cb, 4, HEIGHT_/2, WIDTH_/2 );
                cb = squeeze( mean( cb, 1 ) )';
                
                cr = reshape( c, 2, HEIGHT_/2, WIDTH_);
                cr = permute( cr, [1, 3, 2] );
                cr = reshape( cr, 4, HEIGHT_/2, WIDTH_/2 );
                cr = squeeze( mean( cr, 1 ) )';
            end
        else
            %  Merge the r, g, and b values
            merge = ...
                cat(1, reshape(c',1,WIDTH_,HEIGHT_), ...
                reshape(b',1,WIDTH_,HEIGHT_), ...
                reshape(a',1,WIDTH_,HEIGHT_));
            merge = reshape(merge,3*WIDTH_,HEIGHT_);
            % flip
            merge = merge(:,HEIGHT_:-1:1);
        end
        
        % write out the audio in one huge chunk, ha ha
        if ~isempty(audio) && (frame_num+frames_read) == 1
            audio_pos = ftell(fout)-riff_size+4;
            %CAUSED THE ERROR - writing two samples of 'JUNK' for files
            %over 2GB
            if(FILESIZE_ < RIFF_LIMIT_)
                fwrite(fout, '01wb', 'uchar'); %FOR AUDIO
                fwrite(fout, BUFFER_SIZE_, 'uint32'); %WRITE THE BUFFER SIZE
            end
            %THIS SHOULD BE PRESENT IN THE "ixXX" Chunk not in the data
            %itself (ix_data) for files over 2GB
            
            % prepare audio output to be in the proper range
            switch (AUDIO_NBITS_/8)
                case 1
                    audio = audio*128+128;
                    type = 'uchar';
                case 2
                    audio = audio*32768;
                    type = 'int16';
                case 3
                    audio = audio*(double(2^23));
                    type = 'bit24';
                case 4
%                     audio = audio*32768;
%                     type = 'int32';
                    %Check for int32 or float 32 bit
                    if(which_32_bit == 0) 
                        %This means that the audio is 32 bit not floating
                        %point.
                        audio = audio*(double(2^31));
                        type = 'int32';
                    elseif(which_32_bit == 1)
                        % This means that the audio is 32 bit floating
                        % point. Audio does not need to be scaled!
                        type = 'float';
                    else
                        warning('Unable to determine if audio is 32 bit or 32 bit floating point!  Regular (not floating point) 32 bit will be used!');
                        audio = audio*(double(2^31));
                        type = 'int32';
                    end
            end
            fwrite(fout, audio', type);
        end
        
        % record offset of frame
        vidFrames(1:4, frame_num) ...
            = typecast( ...
            cast(ftell(fout)-riff_size+4, 'uint32'), 'uint8');
        
        fwrite(fout, '00db', 'uchar');
        fwrite(fout, FRM_SIZE_OUT_, 'uint32');
        if strcmpi(CODEC_, 'YV12')
            fwrite(fout,  a', 'uchar');
            fwrite(fout, cr', 'uchar');
            fwrite(fout, cb', 'uchar');
        elseif strcmpi(CODEC_, 'v210')
            % Picture of what the bytes look like coming out: 1 char=1 bit
            %   ///-CB-/// ////-Y-/// ///-CR-/// XX     - 1st 32 bits
            %   ////-Y-/// ///-CB-/// ////-Y-/// XX     - 2nd 32 bits
            %   ///-CR-/// ////-Y-/// ///-CB-/// XX     - 3rd 32 bits
            %   ////-Y-/// ///-CR-/// ////-Y-/// XX     - 4th 32 bits
            mask = zeros(1, FRM_SIZE_OUT_/4, 'uint32');
            merge = uint32(reshape(merge, 3, (2*WIDTH_*HEIGHT_)/3));
            % append first row to the output and then shift it up
            mask = bitor(mask, merge(3, :));
            mask = bitshift(mask, 10);
            % append second row to the output and then shift it up
            mask = bitor(mask, merge(2, :));
            mask = bitshift(mask, 10);
            % append third row to the output
            mask = bitor(mask, merge(1, :));
            
            fwrite(fout, mask, 'uint32');
        else
            fwrite(fout, merge, 'uchar');
        end
        frame_num = frame_num + 1;
    end
    
    % fill in the size of the riff (we didn't know this before)
    ret = ftell(fout);
    fseek(fout, riff_size, -1);
    fwrite(fout, ret-riff_size-4, 'uint32');
    % fill in the size of the movi list
    fseek(fout, movi_size, -1);
    fwrite(fout, ret-movi_size-4, 'uint32');
    fseek(fout, ret, -1);
    
    % create an idx1 chunk if this is the first RIFF
    if (riff_num == 1)
        % name of chunk
        fwrite(fout, 'idx1', 'uchar');
        % size of chunk
        if AUDIO_RATE_ > 0
            ck_size = frame_num*16;
        else
            ck_size = (frame_num-1)*16;
        end
        fwrite(fout, typecast(cast(ck_size, 'uint32'), ...
            'uint8'), 'uint8');
        idx = zeros(4, ck_size/4);
        % '00db'
        idx(1:2, 1:4:end) = '0';
        idx(  3, 1:4:end) = 'd';
        idx(  4, 1:4:end) = 'b';
        % 00 00 00 10 (hex)
        idx(  1, 2:4:end) =  16;
        if AUDIO_RATE_ > 0
            idx( 2, 1) = '1';
            idx( 3, 1) = 'w';
            idx( 4, 1) = 'b';
            idx( :, 3) = typecast(cast(audio_pos, 'uint32'), 'uint8');
            idx( :, 4) = typecast(cast(BUFFER_SIZE_, 'uint32'), ...
                'uint8');
            % frame offset
            %ORIGINAL ESTIMATE OF vidFrames NEEDS TO BE CHECKED!
            if(size(idx(1:4, 7:4:end),2) ~= size(vidFrames,2))
                %Estimate was wrong, need to re-adjust the vidFrames to
                %fit.
                off_by = size(vidFrames,2) - size(idx(1:4, 7:4:end),2);
                vidFrames(:,(size(vidFrames,2)-off_by+1):size(vidFrames,2)) = [];
            end
            
            idx(1:4, 7:4:end) = vidFrames;
                
            % frame size
            fsize = typecast(cast(FRM_SIZE_OUT_, 'uint32'), ...
                'uint8');
            idx(  1, 8:4:end) = fsize(1);
            idx(  2, 8:4:end) = fsize(2);
            idx(  3, 8:4:end) = fsize(3);
            idx(  4, 8:4:end) = fsize(4);
        else
            % frame offset
            idx(1:4, 3:4:end) = vidFrames;
            % frame size
            fsize = typecast(cast(FRM_SIZE_OUT_, 'uint32'), ...
                'uint8');
            idx(  1, 4:4:end) = fsize(1);
            idx(  2, 4:4:end) = fsize(2);
            idx(  3, 4:4:end) = fsize(3);
            idx(  4, 4:4:end) = fsize(4);
        end
        
        % offsets and sizes of frames throughout file
        fwrite(fout, idx, 'uchar');
    end
    
    % record the offsets of all the frames to be placed in 'ixXX'
    % chunks later
    totFrames = cat(2, totFrames, vidFrames);
    % record the number of frames that will be stored in
    % each 'ixXX' chunk
    numFrames(2, size(numFrames, 2)) = frame_num-1; %#ok<AGROW>
    frames_read = frames_read + frame_num - 1;
    
    riff_num = riff_num + 1;
    clear vidFrames;
end
if (riff_num > 2) % clarification: if more than one riff
    % write out each ixXX chunk
    cur = 1;
    indx = zeros(2, size(numFrames, 2));
    
    % add 8 to the offsets because the ixXX indexes point to
    % data instead of chunks.
    for frm=1:size(totFrames, 2)
        offset = typecast(cast(totFrames(:, frm), 'uint8'), ...
            'uint32');
        offset = offset + 8;
        totFrames(:, frm) = typecast(cast(offset, 'uint32'), ...
            'uint8');
    end
    
    for ix = 1:size(numFrames, 2),
        ix_size = 24 + 8*numFrames(2, ix);
        ix_data = zeros(4, 2+(ix_size/4));
        % index name
        ix_data(1:4, 1) = 'ix00';
        % chunk size
        ix_data(1:4, 2) ...
            = typecast(cast(ix_size, 'uint32'), 'uint8');
        % 01 00 00 02
        ix_data(  1, 3) = 2;
        ix_data(  4, 3) = 1;
        % number of frames indexed in this chunk
        ix_data(1:4, 4) ...
            = typecast(cast(numFrames(2, ix), 'uint32'), 'uint8');
        ix_data(1:4, 5) = '00db';
        % offset of parent RIFF chunk
        
        ix_data(1:4, 6:7) = reshape(typecast(cast( ...
            numFrames(1, ix), 'uint64'), 'uint8'), 4, 2);
        % frame size
        fsize = typecast(cast(FRM_SIZE_OUT_, 'uint32'), ...
            'uint8');
        ix_data(  1, 10:2:(numFrames(2, ix)*2+8)) = fsize(1);
        ix_data(  2, 10:2:(numFrames(2, ix)*2+8)) = fsize(2);
        ix_data(  3, 10:2:(numFrames(2, ix)*2+8)) = fsize(3);
        ix_data(  4, 10:2:(numFrames(2, ix)*2+8)) = fsize(4);
        % frame offset
        ix_data(:, 9:2:(numFrames(2, ix)*2+8)) ...
            = totFrames(:, cur:(numFrames(2, ix)+cur-1));
        
        % record the position of this index
        indx(1, ix) = ftell(fout);
        % record the size of this index
        indx(2, ix) = numel(ix_data);
        
        fwrite(fout, ix_data, 'uchar');
        cur = cur + numFrames(2, ix);
    end
    % fill in the indx chunk with information gathered from indexes
    ix_out = zeros(4, numel(indx)*2);
    for ix = 1:4:size(ix_out, 2)
        ind = cast((ix/4)+1, 'uint8');
        % cast the RIFF offset to a 64-bit int to hold more than
        % 2 gb, and then split into 8 bytes to write to the file
        ix_out(:, ix:(ix+1)) = ...
            reshape(typecast(cast(indx(1, ind), 'uint64'), ...
            'uint8'), 4, 2);
    end
    % output the size of the index
    ix_out(:, 3:4:end) = ...
        reshape(typecast( ...
        cast(indx(2, :), 'uint32'), 'uint8'), 4, riff_num-1);
    % output the number of frames in the index
    ix_out(:, 4:4:end) = ...
        reshape(typecast( ...
        cast(numFrames(2, :), 'uint32'), 'uint8'), 4, riff_num-1);
    
    fseek(fout, ix_vid+12, -1);
    % write out how many indexes there are
    fwrite(fout, size(indx, 2), 'uint32');
    fseek(fout, 16, 0);
    % write out locations and sizes of indexes
    fwrite(fout, ix_out, 'uchar');
    
    if AUDIO_RATE_ > 0
        % write out each ixXX chunk
        indx = zeros(2, 1);
        
        ix_size = 32;
        ix_data = zeros(4, 2+(ix_size/4));
        % index name
        ix_data(1:4, 1) = 'ix01';
        % chunk size
        ix_data(1:4, 2) ...
            = typecast(cast(ix_size, 'uint32'), 'uint8');
        % 01 00 00 02
        ix_data(  1, 3) = 2;
        ix_data(  4, 3) = 1;
        % number of frames indexed in this chunk
        ix_data(  1, 4) = 1;
        ix_data(1:4, 5) = '01wb';
        
        % frame offset
        ix_data( : ,  9) = typecast(cast(audio_pos, 'uint32'), ...
            'uint8');
        % frame size
        ix_data( : , 10) = typecast(cast(BUFFER_SIZE_, 'uint32'), ...
            'uint8');
        
        % record the position of this index
        indx(1, 1) = ftell(fout);
        % record the size of this index
        indx(2, 1) = numel(ix_data);
        
        fwrite(fout, ix_data, 'uchar');
        
        % fill in the indx chunk with information gathered from indexes
        ix_out = zeros(4, numel(indx)*2);
        for ix = 1:4:size(ix_out, 2)
            ind = cast((ix/4)+1, 'uint8');
            % cast the RIFF offset to a 64-bit int to hold more than
            % 2 gb, and then split into 8 bytes to write to the file
            ix_out(:, ix:(ix+1)) = ...
                reshape(typecast(cast(indx(1, ind), 'uint64'), ...
                'uint8'), 4, 2);
        end
        % output the size of the index
        ix_out(:, 3:4:end) = ...
            reshape(typecast( ...
            cast(indx(2, :), 'uint32'), 'uint8'), 4, 1);
        % output the number of frames in the index
        ix_out(  1, 4) = 1;
        
        fseek(fout, ix_aud+12, -1);
        % write out how many indexes there are
        fwrite(fout, size(indx, 2), 'uint32');
        fseek(fout, 16, 0);
        % write out locations and sizes of indexes
        fwrite(fout, ix_out, 'uchar');
    end
end

fclose(fout);
return ;

% ----------------------------------------------------------------------
function [hdrl, ix_vid, ix_aud] = fillHDRL()
% returns:
% hdrl      - all the header information for the file, ready for writing
% ix_vid    - if the file is > 2gb, this is the position of the XXix
%             chunk for video data which is the file's super index
% ix_aud    - if the file is > 2gb, this is the position of the XXix
%             chunk for audio data which is the file's super index

global AUDIO_RATE_

hdrl(1:4, 1) = 'hdrl';

avih = fillAVIH();
hdrl = [hdrl avih];

[vids, ix_vid] = fillVIDS();
ix_vid = ix_vid + numel(hdrl);
hdrl = [hdrl vids];

ix_aud = 0;
if AUDIO_RATE_ > 0
    [auds, ix_aud] = fillAUDS();
    ix_aud = ix_aud + numel(hdrl);
    hdrl = [hdrl auds];
end
return ;

% ----------------------------------------------------------------------
function [avih] = fillAVIH()

global FPS_
global NUM_FRAMES_
global WIDTH_
global HEIGHT_
global FILESIZE_
global AUDIO_RATE_

global RIFF_LIMIT_

avih = zeros(4, 16);

avih(1:4, 1) = 'avih';
% size of chunk
avih(1:4, 2) = typecast(cast(56, 'uint32'), 'uint8');

microSecPerFrame = cast(1/(FPS_*10^-6), 'uint32');
avih(1:4, 3) = typecast(microSecPerFrame, 'uint8');
% Max bytes per second. I still don't know how to calculate
% this, but 20737627 is common. How this number is derived is unknown. 
% This and the other constants below are part of the AVI header that 
% describe the audio. 
if (FILESIZE_ > RIFF_LIMIT_)
    avih( : , 4) = typecast(cast(124292613, 'uint32'), 'uint8');
else
    if (AUDIO_RATE_ > 0)
        % avih( : , 4) = typecast(cast(6277241, 'uint32'), 'uint8');
        avih( : , 4) = typecast(cast(4709907, 'uint32'), 'uint8');
    else
        avih( : , 4) = typecast(cast(20737627, 'uint32'), 'uint8');
    end
end
% flag bits - 16 to indicate this file has an index
avih(1:4, 6) = typecast(cast(16, 'uint32'), 'uint8');

avih(1:4, 7) = typecast(cast(NUM_FRAMES_, 'uint32'), 'uint8');
% write out num streams
avih(  1, 9) = 1;
if AUDIO_RATE_ > 0
    avih(  1, 9) = 2;
    % flag bits - +256 to indicate this file is interleaved
    avih(1:4, 6) = typecast(cast(16+256, 'uint32'), 'uint8');
end

avih(1:4,11) = typecast(cast( WIDTH_, 'uint32'), 'uint8');
avih(1:4,12) = typecast(cast(HEIGHT_, 'uint32'), 'uint8');
return ;

% ----------------------------------------------------------------------
function [vids, ix_pos] = fillVIDS()

global FILESIZE_
global RIFF_LIMIT_

vids(1:4, 1) = 'LIST';
vids(1:4, 2) = 0;
vids(1:4, 3) = 'strl';

strh = fillSTRH_vid();
vids = [vids strh];

strf = fillSTRF_vid();
vids = [vids strf];

ix_pos = numel(vids);
if (FILESIZE_ >= RIFF_LIMIT_)
    indx = fillINDX('00db');
    vids = [vids indx];
end
vids(1:4, 2) = typecast(cast(numel(vids)-8,'uint32'),'uint8');
return ;

% ----------------------------------------------------------------------
function [auds, ix_pos] = fillAUDS()

global FILESIZE_
global RIFF_LIMIT_

auds(1:4, 1) = 'LIST';
auds(1:4, 2) = 0;
auds(1:4, 3) = 'strl';

strh = fillSTRH_aud();
auds = [auds strh];

strf = fillSTRF_aud();
auds = [auds strf];

ix_pos = numel(auds);
if (FILESIZE_ >= RIFF_LIMIT_)
    indx = fillINDX('01wb');
    auds = [auds indx];
end
auds(1:4, 2) = typecast(cast(numel(auds)-8,'uint32'),'uint8');
return ;

% ----------------------------------------------------------------------
function [strh] = fillSTRH_vid()

global FPS_
global NUM_FRAMES_
global WIDTH_
global HEIGHT_
global FILESIZE_
global FRM_SIZE_OUT_
global COLOR_
global CODEC_

strh = zeros(4, 16);

strh(1:4, 1) = 'strh';
% chunk size
strh(1:4, 2) = typecast(cast(56, 'uint32'), 'uint8');
strh(1:4, 3) = 'vids';
if strcmpi(COLOR_, 'UYVY')
    strh(1:4, 4) = CODEC_;
else
    strh(1:4, 4) = COLOR_;
end
% special cases for 29.97, 59.94 and 23.98.  These are needed so that
% the FM sound carrier did not interact with the color subcarrier to
% produce visible color artifacts in the image.  Consequently, it is
% very important to write the exactly correct values, otherwise the
% audio and video will not play synchronously.
if 29.97 - 0.01 <= FPS_ && FPS_ <= 29.97 + 0.01,
    fps_numerator =  30000;
    fps_denominator = 1001;
elseif 59.94 - 0.01 <= FPS_ && FPS_ <= 59.94 + 0.01,
    fps_numerator =  60000;
    fps_denominator = 1001;
elseif 23.98 - 0.01 <= FPS_ && FPS_ <= 23.98 + 0.01,
    fps_numerator =  24000;
    fps_denominator = 1001;
else
    fps_numerator = FPS_*100;
    fps_denominator = 100;
end
strh( : , 8) = typecast(cast(fps_denominator, 'uint32'), 'uint8');
strh( : , 9) = typecast(cast(fps_numerator, 'uint32'), 'uint8');
strh(1:4,11) = typecast(cast(  NUM_FRAMES_, 'uint32'), 'uint8');
strh( : ,12) = typecast(cast(FRM_SIZE_OUT_, 'uint32'), 'uint8');
strh(1:2,16) = typecast(cast(       WIDTH_, 'uint16'), 'uint8');
strh(3:4,16) = typecast(cast(      HEIGHT_, 'uint16'), 'uint8');
return ;

% ----------------------------------------------------------------------
function [strh] = fillSTRH_aud()

global AUDIO_RATE_
global SAMPLE_SIZE_
global BUFFER_SIZE_

strh = zeros(4, 16);

strh(1:4, 1) = 'strh';
% chunk size
strh(1:4, 2) = typecast(cast(56, 'uint32'), 'uint8');
strh(1:4, 3) = 'auds';

% I don't really know what these 2 are...
strh( 1 , 7) = 1;
strh( 1 , 8) = 1;
strh(1:4, 9) = typecast(cast(AUDIO_RATE_, 'uint32'), 'uint8');
strh( : ,11) = typecast(cast(BUFFER_SIZE_/SAMPLE_SIZE_, ...
    'uint32'), 'uint8');
strh(1:4,12) = typecast(cast(BUFFER_SIZE_, ...
    'uint32'), 'uint8');
strh( : ,14) = typecast(cast(SAMPLE_SIZE_  , 'uint32'), 'uint8');
return ;

% ----------------------------------------------------------------------
function [strf] = fillSTRF_vid()

global WIDTH_
global HEIGHT_
global FRM_SIZE_OUT_
global COLOR_
global CODEC_

strf = zeros(4, 12);

strf(1:4, 1) = 'strf';
% size of chunk
strf(1:4, 2) = typecast(cast(40, 'uint32'), 'uint8');
% bitmap header size
strf(1:4, 3) = typecast(cast(40, 'uint32'), 'uint8');
% width and height
strf(1:4, 4) = typecast(cast(WIDTH_, 'uint32'), 'uint8');
strf(1:4, 5) = typecast(cast(HEIGHT_, 'uint32'), 'uint8');
% number of planes
strf(1:2, 6) = typecast(cast(1, 'uint16'), 'uint8');
% bit depth & compression type
if strcmpi(COLOR_, 'UYVY')
    strf(3:4, 6) = typecast(cast(16, 'uint16'), 'uint8');
    if strcmpi(CODEC_, 'v210')
        strf(1:4, 7) = CODEC_;
    elseif strcmpi(CODEC_, 'YV12')
        strf(1:4, 7) = CODEC_;
        strf(3:4, 6) = typecast(cast(12, 'uint16'), 'uint8');
    else
        strf(1:4, 7) = COLOR_;
    end
else
    strf(3:4, 6) = typecast(cast(24, 'uint16'), 'uint8');
    strf(1:4, 7) = 0;
end
% size of frame
strf( : , 8) = typecast(cast(FRM_SIZE_OUT_, 'uint32'), 'uint8');
return ;

% ----------------------------------------------------------------------
function [strf] = fillSTRF_aud()

global AUDIO_RATE_
global AUDIO_NBITS_
global NUM_CHANNELS_
global SAMPLE_SIZE_
global which_32_bit

strf = zeros(4, 6);

strf(1:4, 1) = 'strf';
% size of chunk
if(NUM_CHANNELS_ > 2 || AUDIO_NBITS_ > 16)
    %For WAVE_FORMAT_EXTENSIBLE(0xfffe) the size of chunk is 40.
    strf(1:4, 2) = typecast(cast(40, 'uint32'), 'uint8');
else
    %For PCM the size of chunk is 16.
    strf(1:4, 2) = typecast(cast(16, 'uint32'), 'uint8');
end
% format tag - 1 = 'PCM' or IEEE floating point (0x3)
if(which_32_bit == 1)
    %32 bit float is what is being written, need to place this information
    %into the header.
    if(NUM_CHANNELS_ > 2)
        %Even though its 32 bit floating point, more than 2 channels
        %requires that it is WAVE_FORMAT_EXTENSIBLE(0xfffe)
        strf(1:2, 3) = typecast(cast( 65534, 'uint16'), 'uint8');
    else
        strf(1:2, 3) = typecast(cast( 3, 'uint16'), 'uint8');
    end
else
    if(NUM_CHANNELS_ > 2 || AUDIO_NBITS_ > 16)
        %PCM is only good up till Mono or Stereo and 8 or 16 bits.  After
        %that the new format is WAVE_FORMAT_EXTENSIBLE (0xfffe)
        strf(1:2, 3) = typecast(cast( 65534, 'uint16'), 'uint8');
    else
        %PCM will be written into the header
        strf(1:2, 3) = typecast(cast( 1, 'uint16'), 'uint8');
    end
end
% number of channels
strf(3:4, 3) = typecast(cast(NUM_CHANNELS_, 'uint16'), 'uint8');
% samples per second
strf(1:4, 4) = typecast(cast(AUDIO_RATE_, 'uint32'), 'uint8');
% bytes per second
BytesPerSecond = AUDIO_RATE_ * NUM_CHANNELS_ * AUDIO_NBITS_/8;
strf(1:4, 5) = typecast(cast(BytesPerSecond, 'uint32'), 'uint8');
% sample size/block align
strf(1:2, 6) = typecast(cast(SAMPLE_SIZE_, 'uint16'), 'uint8');
strf(3:4, 6) = typecast(cast(AUDIO_NBITS_, 'uint16'), 'uint8');
%NEW for WAVE_FORMAT_EXTENSIBLE
%Bits Per Sample
if(NUM_CHANNELS_ > 2 || AUDIO_NBITS_ > 16)
    %Size of extension (cbSize) 22 for WAVE_FORMAT_EXTENSIBLE
    strf(1:2, 7) = typecast(cast(22, 'uint16'), 'uint8');
    %Valid Bits Per Sample
    strf(3:4, 7) = typecast(cast(AUDIO_NBITS_, 'uint16'), 'uint8');
    %dwChannelMask (Speaker position mask)
    if(NUM_CHANNELS_ == 6)
        strf(1:4, 8) = typecast(cast(63, 'uint32'), 'uint8');
    elseif(NUM_CHANNELS_ == 4)
        strf(1:4, 8) = typecast(cast(33, 'uint32'), 'uint8');
    elseif(NUM_CHANNELS_ == 2)
        strf(1:4, 8) = typecast(cast(3, 'uint32'), 'uint8');
    elseif(NUM_CHANNELS_ == 1)
        %Front Left Speaker
        strf(1:4, 8) = typecast(cast(1, 'uint32'), 'uint8');
    else
        %Default set to 6 channels
        strf(1:4, 8) = typecast(cast(63, 'uint32'), 'uint8');
    end
    %SubFormat (GUID (first two bytes are the data format code))
    %This is placing the SubFormat in the AVI header.  This is placing that
    %the SubFormat is the following: KSDATAFORMAT_SUBTYPE_PCM
    if(which_32_bit == 0)
        %This is placing that
        %the SubFormat is the following: KSDATAFORMAT_SUBTYPE_PCM
        strf(1, 9) = typecast(cast(1, 'uint8'), 'uint8');
        strf(2, 9) = typecast(cast(0, 'uint8'), 'uint8');
        strf(3, 9) = typecast(cast(0, 'uint8'), 'uint8');
        strf(4, 9) = typecast(cast(0, 'uint8'), 'uint8');
        strf(1, 10) = typecast(cast(0, 'uint8'), 'uint8');
        strf(2, 10) = typecast(cast(0, 'uint8'), 'uint8');
        strf(3, 10) = typecast(cast(16, 'uint8'), 'uint8');
        strf(4, 10) = typecast(cast(0, 'uint8'), 'uint8');
        strf(1, 11) = typecast(cast(128, 'uint8'), 'uint8');
        strf(2, 11) = typecast(cast(0, 'uint8'), 'uint8');
        strf(3, 11) = typecast(cast(0, 'uint8'), 'uint8');
        strf(4, 11) = typecast(cast(170, 'uint8'), 'uint8');
        strf(1, 12) = typecast(cast(0, 'uint8'), 'uint8');
        strf(2, 12) = typecast(cast(56, 'uint8'), 'uint8');
        strf(3, 12) = typecast(cast(155, 'uint8'), 'uint8');
        strf(4, 12) = typecast(cast(113, 'uint8'), 'uint8');
    else
        %32 Bit IEEE Floating Point
        %This is placing that
        %the SubFormat is the following:  KSDATAFORMAT_SUBTYPE_IEEE_FLOAT
        strf(1, 9) = typecast(cast(3, 'uint8'), 'uint8');
        strf(2, 9) = typecast(cast(0, 'uint8'), 'uint8');
        strf(3, 9) = typecast(cast(0, 'uint8'), 'uint8');
        strf(4, 9) = typecast(cast(0, 'uint8'), 'uint8');
        strf(1, 10) = typecast(cast(0, 'uint8'), 'uint8');
        strf(2, 10) = typecast(cast(0, 'uint8'), 'uint8');
        strf(3, 10) = typecast(cast(16, 'uint8'), 'uint8');
        strf(4, 10) = typecast(cast(0, 'uint8'), 'uint8');
        strf(1, 11) = typecast(cast(128, 'uint8'), 'uint8');
        strf(2, 11) = typecast(cast(0, 'uint8'), 'uint8');
        strf(3, 11) = typecast(cast(0, 'uint8'), 'uint8');
        strf(4, 11) = typecast(cast(170, 'uint8'), 'uint8');
        strf(1, 12) = typecast(cast(0, 'uint8'), 'uint8');
        strf(2, 12) = typecast(cast(56, 'uint8'), 'uint8');
        strf(3, 12) = typecast(cast(155, 'uint8'), 'uint8');
        strf(4, 12) = typecast(cast(113, 'uint8'), 'uint8');
    end
end

return ;

% ----------------------------------------------------------------------
function [indx] = fillINDX( kind )
% kind is either '01wb' for audio or '00db' for video

indx = zeros(4, 502);

indx(1:4, 1) = 'indx';
indx(1:4, 2) = typecast(cast(2000, 'uint32'), 'uint8');
indx(  1, 3) = 4;
indx(1:4, 5) = kind;
return ;

