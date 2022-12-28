function [] = convert2avi(infile, outfile)
%   Convert any video file readable by MATLAB into an uncompressed AVI.
% SYNTAX
%    convert2avi(infile, outfile)
% SEMANTICS
%   Copy video from <infile> to uncompressed AVI file <outfile>. 
%   As of the time this function is written, MATLAB always returns RGB color
%   space. Function convert2avi() will convert the video YCbCr 422. 
%   This motivation is to avoid problems caused by MATLAB's functions
%   Videoreader(), readFrame(), and hasFrame().
%
%   Convert2avi must hold the entire video in memory. It will fail if
%   this is not possible. 

    v = VideoReader(infile);

    % make sure is RGB color space
    if ~strcmp(v.VideoFormat,'RGB24')
        error('color space of video file not recognized');
    end

    cnt = 1;
    while hasFrame(v)
        tmp = readFrame(v);
        [y, cb, cr] = rgb2ycbcr_double(single(tmp), '128', 'y_cb_cr');

        all_y(:,:,cnt) = y;
        all_cb(:,:,cnt) = cb;
        all_cr(:,:,cnt) = cr;
        
        cnt = cnt + 1;
    end
    
    write_avi('YCbCr', all_y, all_cb, all_cr, 'YCbCr', outfile, v.FrameRate, '128');
end
