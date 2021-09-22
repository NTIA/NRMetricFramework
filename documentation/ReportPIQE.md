# Report on Perception Based Image Quality Evaluator (PIQE) Metric

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Function `nrff_piqe.m` implements the Perception based Image Quality Evaluator (PIQE) metric, as presented in [[29]](Publications.md) and [[30]](Publications.md), using code made available from MATLAB®. PIQE does not work reliably across a broad range of modern camera systems and video content. 

Goal | Metric Name|Rating
-----|------------|------
MOS  | PIQE | :star:

## Algorithm Summary 
See MATLAB® help for an algorithm summary.

## Speed and Conformity
NR-PWN took __1.5×__ as long to run as the benchmark metric, [nrff_blur.md](ReportBlur.md).

Conformity is ensured by using MATLAB's implementation of PIQE. When applied to videos, `nrff_piqe.m` takes the average over all frames.

## Analysis

The authors report 0.90 Pearson correlation between PIQE and MOS for the LIVE Image Quality Assessment Database Release 2 [[30]](Publications.md), 0.87 Pearson correlation between PIQE and MOS for the CSIQ dataset [[33]](Publications.md), and 0.86 Pearson correlation between PIQE and MOS for the TID2008 dataset [[32]](Publications.md). 

PIQE does not respond well to diverse content and camera impairments. The correlations are low and PIQE values between 20 and 40 are typically associated with the full range of MOSs. Note that the red fit line has a negative slope for the BID dataset but a positive slope for the CID2013 dataset. 
```
1) piqe_mean 
bid              corr =  0.26  rmse =  0.98  percentiles [16.91,31.94,38.00,45.03,84.43]
ccriq            corr =  0.04  rmse =  1.02  percentiles [13.81,28.62,38.09,50.05,84.13]
cid2013          corr =  0.37  rmse =  0.84  percentiles [13.40,33.32,41.77,48.36,100.00]
C&V              corr =  0.17  rmse =  0.71  percentiles [22.02,35.69,42.43,47.65,61.04]
its4s2           corr =  0.02  rmse =  0.74  percentiles [12.99,35.58,42.15,49.01,77.75]
LIVE-Wild        corr =  0.08  rmse =  0.82  percentiles [13.74,35.85,42.37,48.91,74.36]

average          corr =  0.16  rmse =  0.85
pooled           corr =  0.02  rmse =  0.88  percentiles [12.99,33.53,41.33,48.59,100.00]
```
![](images/report_piqe.png)
