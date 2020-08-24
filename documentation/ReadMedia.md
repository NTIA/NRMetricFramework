
# MATLAB function `read_media.m`

## Usage

This code combines reading images and videos with standard pre-processing specified in a [dataset structure](DatasetStructure.md). This code is intended to be called by [calculate_NRpars](CalculateNRpars.md).

## Details

This function uses three different mechanisms to read media, depending on the file type:
* Images in JPEG or PNG files
* Videos in uncompressed AVI, YCbCr or RGB format
* Any video file that can be read by MATLAB’s `VideoReader` function 

If the media is an image, the code uses MATLAB’s `Imread` function. 

If the media is an uncompressed AVI file in either YCbCr or RGB color space, then the code uses the [read_avi.m](ReadAvi.md) function provided with this repository. The AVI file format has not changed in decades, and neither has this code. 

Otherwise, the code uses Matlab’s `VideoReader` function. As of 2019, there are several unresolved bugs in MATLAB’s `VideoReader` function that interact poorly with **read_media.m**. 
This may cause unreported read errors at the beginning or end of the video (e.g., frame read twice, frame skipped.md). 
We recommend using function [convert_media.m](ConvertMedia.md) to convert such videos into uncompressed AVI files, to avoid these bugs. 

After the image or video is read, it is converted into the YCbCr color space. Interlaced video will be de-interlaced by splitting each frame into fields and up sampling to the full frame size. The display size and valid region processing specified in the media structure is applied (i.e., scale to the monitor, discard pixels outside the valid region). Color planes will be up-sampled with pixel replication where necessary, so that Y, Cb, and Cr planes are all the same size.

## Inline Documentation
```text
SYNTAX

>>  [y] = read_media ('all', nr_dataset, media_num);
>>  [y] = read_media ('frames', nr_dataset, media_num, start, stop);
>>  [y] = read_media (..., 'PropertyName', PropertyValue1, PropertyValue2, ...);
>>  [y, cb, cr] = read_media (...);

SEMANTICS

  Read an image or segment of video associated with one media in a dataset structure. 
  nr_dataset is the dataset structure, and `media_num` is the index of the media to be read.
  This function has three modes:
   * Mode 'all' reads the entire media
   * Mode 'frames' reads the specified range of frames (`start` to `stop`)

  Return value Y contains the read images as a 3-D matrix (row, column, time).  
  Return values Cb and Cr contain the color image planes. 

  The following optional arguments may be appended: 

  'region',top, left, bottom, right,
                       Requested spatial region of interest, overriding
                       the media's specified valid region. \
 
  'interlace'          If the media is an interlaced video, return the raw pixels. 
                       By default, interlaced videos are deinterlaced by 
                       spliting into fields, and up-sampling each field to a full frame.
```
