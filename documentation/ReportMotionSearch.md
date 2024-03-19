# Report on Motion Search

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Function `nrff_motion_search.m` calls motion_search.exe from [this GitHub repository](https://github.com/facebookresearch/motion-search). 
The goal is to determine whether the features calculated by motion_search can be used to predict MOS in general and/or to predict coding complexity specifically.


## Algorithm Summary
Function motion_search.exe implements a general motion search algorithm.

## Speed and Conformity

The motion_search.exe function is very fast. 
Most of the time required is used to convert the video into the format required (i.e., read and write speed). 

Function `nrff_motion_search.exe` uses the software produced by the authors. 

## Analysis

Analysis is not yet available. 
