# Report on PatchVQ

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Patch VQ was evaluated from [this GitHub repository](https://github.com/baidut/PatchVQ) as described in [[53]](Publications.md).
The goal is to determine whether the features calculated by patchVQ or the final metric produced by patchVQ can be used to predict MOS in general and/or to predict coding complexity specifically.


## Algorithm Summary


Goal|Metric Name|Rating
----|-----------|------
MOS|PatchVQ|:question: 


## Speed and Conformity

Patch VQ is a suite of metrics that aims to "patch up" the video quality problem. The software is released under the Creative Commons Attribution 3.0 license.

The research team had issues installing and running PatchVQ suite. The dependencies the package relied on were out of date and a stable windows environment could not be attained.

The research team reached out to the authors and were informed the original environment for this software package was intended for a Linux environment, using a CUDA device. 



## Analysis

Because the NRMetricFramework is a MATLAB/Windows based project and intended to be run on common hardware, the team decided it would be best to investigate other metrics that are easier to integrate into the NRMetricFramework environment.



There was no feature function generated for this software package. The red question mark rating was given to patch VQ as the research team was not able to run patch VQ in the Windows environment.



