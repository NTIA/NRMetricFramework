# Report on the Blind/Referenceless Image Spatial Quality Evaluator (BRISQUE)

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Function `nrff_brisque.m` implements the Blind/Referenceless Image Spatial Quality Evaluator (BRISQUE), an image quality metric presented in [[8]](Publications.md). BRISQUE does not work reliably across a broad range of modern camera systems and video content. 

Goal|Metric Name|Rating
----|-----------|------
MOS|BRISQUE|:star:

__R&D Potential__: MATLAB® offers tools to retrain BRISQUE for a target application. Users must provide their own data (images with MOSs). 

## Algorithm Summary
BRISQUE uses a support vector regression (SVR) model trained by MATLAB on an image database containing standard image distortions. If a distortion is not included in that dataset, BRISQUE will not be able to evaluate the quality of an image affected by it. BRISQUE calculates a nonnegative scalar in the range of [0,100] with lower scores reflecting a higher level of perceptual quality. The properties of the default model are listed in `nrff_brisque.m` and at the MathWorks® webpage (https://www.mathworks.com/help/images/ref/brisquemodel.html)

## Speed and Conformity
BRISQUE took __1.5×__ as long to run as the benchmark metric, [nrff_blur.md](ReportBlur.md). 

The MathWorks documentation does not describe the complexity of the algorithm, and [8] does not list computational complexity explicitly in terms of Big-O. 

Code is provided by MATLAB.

## Analysis
The authors report 0.9424 Pearson correlation between BRISQUE and MOS for the 2006 LIVE Image Quality Assessment Database [[31]](Publications.md), 

BRISQUE does not respond well to diverse content and camera impairments. The correlations are low and BRISQUE values above the 25th percentile are associated with the full range of MOSs. 
```
1) brisque_MEAN 
bid              corr =  0.07  rmse =  1.01  percentiles [ 8.44,25.01,32.14,39.69,53.65]
ccriq            corr =  0.26  rmse =  0.98  percentiles [ 3.56,26.42,34.77,40.58,58.44]
cid2013          corr =  0.02  rmse =  0.90  percentiles [ 1.94,25.90,31.96,36.79,  NaN]
C&V              corr =  0.30  rmse =  0.69  percentiles [ 0.61,18.19,24.39,33.44,49.67]
its4s2           corr =  0.19  rmse =  0.73  percentiles [ 0.27,20.65,28.26,36.24,57.55]
LIVE-Wild        corr =  0.21  rmse =  0.80  percentiles [ 0.58,19.90,27.24,35.61,63.03]

average          corr =  0.17  rmse =  0.85
pooled           corr =  0.17  rmse =  0.87  percentiles [ 0.27,22.13,29.88,37.53,  NaN]

```
![](images/report_brisque.jpg)