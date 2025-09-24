# Report on AGH-VQIS

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Function `nrff_agh_vqis.m` calls python in a virtual environment and runs a script to invoke the agh-vqis algorithm. The agh-vqis code was downloaded from [the agh-vqis PyPi page](https://pypi.org/project/agh-vqis/) and is described in [[52]](Publications.md) The generated metrics are exported to a temporary csv that is imported into MATLAB. 
The goal is to determine whether the features calculated by agh-vqis can be used for RCA or to predict MOS in general.

## Algorithm Summary
Function nrff_agh_vqis implements a set of NR metric algorithms that detect specific impairments.

Goal|Metric Name|Rating
----|-----------|------
MOS|agh-vqis|:question:

## Speed and Conformity

The agh-vqis python implementation is very fast. 

Function `nrff_agh_vqis.m` uses the software produced by the authors available [here](https://qoe.agh.edu.pl/indicators/). 
The software provides data for each frame, so `nrff_agh_vqis.m` calculates parameters as the mean value of each feature over the video clip.

## Analysis

We encountered numerous problems when running this code. The software sometimes crashed or produced invalid data. Agh-vqis was given a red question mark as the research team was not able to run the software on multiple datasets and therefore could not reach final conclusion on the usefulness of the package.

The agh-vqis code generates 15 features for each frame of the input video clip. Some of these features are not present in this repository's datasets, like slicing and flickering. Below is our preliminary thoughts on the agh-vqis features, indicating features for further investigation. 

Feature|Parameter|Rating
----|----------|------
Blockiness|Blockiness_mean|:star: :star:
SA|SA_mean|:star: :star:
Letterbox|Letterbox_mean|:star: :star:
Pillarbox|Pillarbox_mean|:star: :star:
Blockloss|Blockloss_mean|:star: :star:
Blur|Blur_mean|:star:
TA|TA_mean|:star:
Blackout|Blackout_mean|:star:
Freezing|Freezing_mean|:star:
Exposure|Exposure_mean|:star:
Contrast|Contrast_mean|:star:
Interlace|Interlace_mean|:star:
Noise|Noise_mean|:star:
Slice|Slice_mean|:question:
Flickering|Flickering_mean|:question:

Of the above metrics, a few were of most interest to the team:

    Blockloss
    Pillarbox
    Letterbox
    SA
    Blockiness
