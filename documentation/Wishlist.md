# Wishlist of Future Capabilities

This page identifies functions that are desired but not yet implemented. See [Demo #1](Demo1.md) for definitions.


## Python Implementation

People who cannot afford MATLAB licenses have expressed interest in a Python implementation of this repository. 

## Analysis Techniques for Ordered Data

[Wang et al.](https://ieee-dataport.org/documents/videoset) make available the University of Southern California (USC) Just Noticeable Difference (JND) dataset. 
The USC JND dataset would be suitable for training NR metrics, if we had statistical methods for evaluating the performance of a dataset on JND data. 
These methods would also let experts quickly create datasets with objective JND ratings, based on expert knowledge (e.g., bit-rate reduction, resolution subsampling).

NR metric [dipIQ](ReportDipIQ) provides analysis techniques that may be suitable. 

## Bitstream Reader
The code in this repository could support bit-stream algorithms for video quality analysis, if bitstream support were added to [read_media.m](ReadMedia.md). Ioannis Katsavounidis and Margaret Pinson propose the following. 

Most of the quality information in an encoded video's bitstream is associated with quantization parameter (QP), quantization scale (QS), and motion vectors (MV).
QP and QS are likely related, and each block may have zero, one, or two MVs. 
Video coders use various block sizes, which may differ within a single image. 
Thus, it would be easiest to report all values on a per-pixel basis. 

We would like a function that reads the video bitstream and returns the following values for each pixel:

Variable | Definition
---|---
`qp` | quantization parameter
`qs` |  quantization scale
`x1` | relative horizontal coordinate of MV1 
`y1` | relative vertical coordinate of MV1
`t1` |  relative time coordinate of MV1
`wt1` | weight of MV1 [0..1]
`flag1` | whether MV1 exists
`x2` | relative horizontal coordinate of MV2 
`y2` | relative vertical coordinate of MV2
`t2` | relative time coordinate of MV2
`wt2` | weight of MV2 [0..1]
`flag2` | whether MV2 exists

where:
* MV1 is motion vector 1
* MV2 is motion vector 2
* Neither MV1 or MV2 will exist for "I" frames
* Both MV1 and MV2 will exist for "B" frames
* Only MV1 will exist for "P" frames
* Negative values indicate up or left
* Positive values indicate down or right

The ffmpeg software would be a suitable starting-point for this function. The easiest solution would be to create a modified version of ffmpeg that saves the above information. Values `x1`, `x2`, `y1`, and `y2` must ignore the standard and instead be measured relative to the current frame as stated above, to avoid confusion among users of this repository.

## Independent Metric 

Currently, there is no way to export a metric outside of the MATLAB ecosystem. The NR metric must either be implemented in another language, or the user must write a wrapper that reads an image or video and calculates the metric. 
