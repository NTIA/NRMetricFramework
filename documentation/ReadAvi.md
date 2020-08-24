# MATLAB function read_avi.m


## Usage

This code is called indirectly by [read_media.m](ReadMedia.md), which is used in [calculate_NRpars](CalculateNRpars.md) to read in AVI files for processing.
Function read_avi.m is more accurate than the video read function supplied by MATLAB but does not support compression. 

## Details

This function takes an avi. file and returns either an information struct about the video (if the 'info' flag is given to the function) or the matrix representation of the image in a given color space depending on the flags given to the function Ie.('YCbCr', 'RGB'). The function can also return the audio track and audio rate if requested (see inline documentation above).

This function is provided and preferred over the normal MATLAB reader function for .avi files because the current MATLAB VideoReader function is unreliable and its behavior is somewhat undefined. In general, prefer the provided functions over MATLAB's unless otherwise specified.


## Inline Documentation
```text
 readAvi
   Reads an uncompressed AVI file of a variety of formats, including
   the following:
       10-bit : uyvy : yuy2 : yv12 : rgb
   If FILENAME does not include an extension, then '.avi' will be used.
 SYNTAX
   [info] = read_avi('Info',filename);
   [c1,c2,c3] = read_avi(color_out,filename);
   [...] = read_avi(...,'flag',...);
 DESCRIPTION
   [info] = read_avi('Info',filename);
       returns only a struct, containing information about the file.
       This struct can then be passed as an argument to this function
       preceded by the 'struct' flag, and the file will be read.
   [c1,c2,c3] = read_avi(color_out,filename);
       returns the color components of the frames read in from the file.
       The color components will depend on color_out. If no frames are
       requested in particular, only the first frame is read.
   [...] = read_avi(...,'Flag',...);
       designates a flag to be set inside the function. See below for a
       complete list of possible flags.
 INPUT ARGUMENTS
   color_out 
   'Info'  -- return listing of header information (see aviinfo).
   'RGB'   -- return image planes in the RGB colorspace.
   'YCbCr' -- return image planes in the YCbCr colorspace.

   filename 
   Avi file to be opened. If the 'struct' flag has
   already been given, do NOT also give a filename

   flag 
   'struct', avi_struct    A struct returned by aviinfo or by this
                           function with the 'Info' property.
   'sroi',top,left,bottom,right,   Spatial region of interest.  By
                                   default, all of each image is
                                   returned.
   'frames',start,stop,    Specify the first and last frames,
                           inclusive, to be read ('start' and 'stop').
                           By default, read first frame.
   '128'               Subtract 128 from all Cb and Cr values.  By
                       default, Cb and Cr values are left in the
                       [0..255] range.
   'interp'            Linearly interpolate Cb and Cr values.  By default,
                       color planes are pixel replicated.  Note:
                       Interpolation is slow. Only implemented for
                       YUV color spaces excepting YV12.
   'audio',['frames' or 'seconds'], start, stop
               Request audio be returned if it exists. If 'frames' are
               requested, the audio for the given frames [1..NumFrames]
               will be returned. If 'seconds' are requested, audio with
               the given duration [0..TotalTime) will be returned. Feel
               free to request more than is in the file; I handle it :)
 OUTPUT ARGUMENTS
   c1 
   Depending on the color_out property, could be Info if 'Info', Y if
   'YCbCr', or R if 'RGB'.

   c2, c3 
   Depending on the color_out property, could be Cb and Cr if 'YCbCr'
   or G and B if 'RGB'.

   c4 
   If audio is requested and exists, this is the raw audio data,
   separated by channels.

   c5 
   if audio is requested and exists, this is the Audio Rate.
 EXAMPLES
 ---[info] = read_avi('Info','twocops.avi');
 ---[r,g,b] = read_avi('RGB','twocops.avi','frames',1,30);
 ---[y,cb,cr] = read_avi('YCbCr','twocops.avi','frames',61,90,'128');
 ---info = aviinfo('my.avi');
   [r, g, b] = read_avi('RGB', 'struct', info);
 ---[y,cb,cr,aud,rate] = read_avi('YCbCr','my.avi','audio','seconds',0,5);
 NOTES
   When reading files with the YV12 fourcc, the cb and cr color
   components will be extrapolated to fit the Y component matrix size.
   The current extrapolation algorithm simply copies the cb and cr
   values. A better implementation might include a bi-linear
   interpolation.

 SIGNATURE
   Programmer: Zebulon Fross
   Version:    08/10/2010

```

