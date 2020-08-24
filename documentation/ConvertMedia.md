# MATLAB FUNCTION convert_media

## Overview

Function takes any video file and converts it into an uncompressed AVI file. 

## Usage

This function is meant for converting alternate video formats into AVI files. This is the preferred format for videos used by this repository.

## Semantics

Function takes a video file and reads it using **vision.VideoFileReader** and converts the video into the YCbCr color space. Each frame is then resized and converted into the proper format for an uncompressed AVI file. Function uses **write_avi()** to write the video file out as an AVI file. Function will fail silently if an error occurs during its execution. 

## Dependencies

This function requires the computer vision toolbox. 


## Inline Documentation
```text
 CONVERT_MEDIA
   Convert a video to uncompressed AVI
 SYNTAX
   convert_media(input_directory, output_directory, filename)
 SEMANTICS
   MATLAB video read function videoReader has severe errors that prevent
   its use. The first frame is occasionally read twice, the last frame
   sometimes exists and sometimes causes Matlab to crash, and this read
   routine may cause the operating system to crash.

   Alternative function (videoFReader) can only be used to read the entire
   file. This would be unacceptably slow, as there is no way to jump to
   the desired frame.

   This function converts all video files in input_directory to
   uncompressed AVI,  and writes them to output_directory.
```
