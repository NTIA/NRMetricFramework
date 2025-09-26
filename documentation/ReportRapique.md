# Report on RAPIQUE

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

The RAPIQUE MATLAB code was downloaded and run from [the RAPIQUE github page](https://github.com/vztu/RAPIQUE) as described in [[54]](Publications.md). The generated metrics are calculated using the MATLAB demo example. 
The goal is to determine whether the features calculated by RAPIQUE can be used for RCA or to predict MOS in general.

## Algorithm Summary
A feature function was not created for this metric.

Goal|Metric Name|Rating
----|-----------|------
MOS|RAPIQUE|:question:

## Speed and Conformity

Function `demo_compute_RAPIQUE_feats.m` uses the software produced by the authors available [here](https://github.com/vztu/RAPIQUE/blob/main/demo_compute_RAPIQUE_feats.m) with documentation available [here](https://ieeexplore.ieee.org/document/9463703). 

The demo code provided by the authors does not fully implement the RAPIQUE algorithm, as described in [55]. The demo RAPIQUE file produces a 3884 dimension vector, which the authors suggest to simplify into one metric by using a regressor head. The authors provide python scripts to train and validate a regression head, but the research team was looking for a complete MATLAB based solution. 

The MATLAB implementation is acceptably fast for video clips. Because the RAPIQUE MATLAB code is only partial to the complete metric generation , the nrff_rapique.m function is incomplete. The major issue that the research team found is the MATLAB implementation does not produce 1 feature per frame, or 1 rating per video clip.



## Analysis

The RAPIQUE github repository gives a demo MATLAB file to calculate the RAPIQUE features, and python scripts to train and validate a deep regressor model. The MATLAB demo file implementation outputs 3884 features per video clip, and does not provide a MATLAB based method to reduce this feature set down to a rating per frame or rating per clip. The authors suggest using a deep regressor head to predict final video quality scores, and provide code to train and validate a deep regressor head in python, but do not provide a pre-trained model to evaluate. Code written in python is more cumbersome to integrate into the MATLAB environment, and is less likely to be ported to low level processors, which is why the research team decided to terminate the evaluation of RAPIQUE. The red question mark rating was given to RAPIQUE as the research team was not able to produce ratings with an out of the box solution.



