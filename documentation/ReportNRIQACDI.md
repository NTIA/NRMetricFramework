# Report on No-Reference Image Quality Assessment for Contrast-Distorted Images (NR-IQA-CDI) 

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Function `nrff_nr_iqa_cdi.m` implements the algorithms implements the five parameters that form the No-Reference Image Quality Assessment for Contrast-Distorted Images (NR-IQA-CDI) metric, as presented in Section II of [[3]](Publications.md). With further research and development, Kurtosis and Entropy may have value for root cause analysis. The other three NR metrics do not work reliably across a broad range of modern camera systems and video content. 

Goal|Metric Name|Rating
----|-----------|------
MOS|Mean|:star:
MOS|Standard Deviation|:star:
MOS|Skewness|:star:
MOS|Kurtosis|:star: :star:
MOS|Entropy|:star: :star:

## Algorithm Summary
The authors of [[3]](Publications.md) recommend the following one- and two-dimensional statistics, calculated from the luma plane:
* Mean - the average value 
* Standard Deviation - the spread of values about the mean
* Skewness - the symmetry or lack thereof 
* Kurtosis - the size of the 'tails' of the data, outliers
* Entropy - randomness, whether the data is predictable or unpredictable 

Ahmed [[3]](Publications.md) reports that these five statistics are used for Natural Scene Statistics (NSS) and can be used well even without Natural Scenes being involved.

## Speed and Conformity

NR-IQA-CDI took __2×__ as long to run as the benchmark metric, [nrff_blur.m](ReportBlur.md). 

Function `nrff_nr_iqa_cdi.m` primarily uses MATLAB® library functions that have a linear runtime, which gives this algorithm a Big-O complexity of O(n) where 'n' is the number of pixels in the image. 

The conformity is excellent when analyzing images. These algorithms are relatively straightforward, and the code needed was already provided by MATLAB. The algorithms are extended to video quality by taking the average over time. 

## Analysis
The Basic Statistics algorithms are evaluated using six image quality datasets that contain camera impairments. The authors do not provide statistics that can be directly compared to our results.

### Mean ###
The correlation coefficients are mediocre, and the distribution is fairly random with a mild positive trend. Compare the scatter of blue dots (for the current dataset) with the green dots (that show the overall response of all datasets). The exception is the CID2013 dataset, which has a relatively high correlation.  

```
1) NR-IQA-CDI mean 
bid              corr =  0.20  rmse =  0.99  false decisions =  30%  percentiles [19.48,87.98,112.26,127.32,195.81]
ccriq            corr =  0.11  rmse =  1.01  false decisions =  34%  percentiles [16.09,72.80,107.33,134.61,233.89]
cid2013          corr =  0.53  rmse =  0.76  false decisions =  20%  percentiles [16.00,77.98,108.87,119.41,183.27]
C&V              corr =  0.14  rmse =  0.71  false decisions =  28%  percentiles [17.15,87.70,113.97,128.30,190.71]
its4s2           corr =  0.20  rmse =  0.73  false decisions =  25%  percentiles [18.20,83.25,106.76,125.90,213.89]
LIVE-Wild        corr =  0.20  rmse =  0.80  false decisions =  26%  percentiles [19.61,89.99,108.52,123.26,214.60]
its4s3           corr =  0.18  rmse =  0.75  false decisions =  25%  percentiles [17.17,61.68,89.74,114.07,216.26]
its4s4           corr =  0.11  rmse =  0.88  false decisions =  36%  percentiles [31.95,88.18,101.98,118.47,193.81]
konvid1k         corr =  0.38  rmse =  0.59  false decisions =  19%  percentiles [17.68,79.43,105.67,124.52,222.00]
its4s            corr =  0.06  rmse =  0.77  false decisions =  34%  percentiles [23.28,77.44,99.53,119.76,198.63]
AGH-NTIA-Dolby   corr =  0.09  rmse =  1.12  false decisions =  39%  percentiles [42.22,72.34,90.88,113.65,150.50]
vqegHDcuts       corr =  0.10  rmse =  0.89  false decisions =  30%  percentiles [26.50,76.63,92.71,109.11,169.74]

average          corr =  0.19  rmse =  0.83
pooled           corr =  0.14  rmse =  0.87  percentiles [16.00,78.62,101.14,121.27,233.89]```
![](images/report_nr_iqa_cdi_mean.png)

### Standard Deviation ###
The correlation coefficients are mediocre, and the distribution is fairly random with a mild positive trend.
```
2) NR-IQA-CDI std 
bid              corr =  0.20  rmse =  0.99  false decisions =  29%  percentiles [ 2.43,28.51,37.58,46.13,74.29]
ccriq            corr =  0.22  rmse =  0.99  false decisions =  29%  percentiles [ 0.74,23.61,29.97,44.27,70.55]
cid2013          corr =  0.24  rmse =  0.87  false decisions =  31%  percentiles [ 0.00,35.10,44.08,55.37,76.22]
C&V              corr =  0.21  rmse =  0.70  false decisions =  25%  percentiles [ 2.16,37.54,51.43,59.70,81.15]
its4s2           corr =  0.24  rmse =  0.72  false decisions =  24%  percentiles [ 2.24,33.52,42.61,51.03,78.49]
LIVE-Wild        corr =  0.16  rmse =  0.81  false decisions =  28%  percentiles [ 4.20,33.23,42.15,50.63,90.43]
its4s3           corr =  0.17  rmse =  0.75  false decisions =  27%  percentiles [ 1.95,20.91,31.20,43.50,79.65]
its4s4           corr =  0.25  rmse =  0.85  false decisions =  26%  percentiles [12.40,30.43,38.05,43.67,59.83]
konvid1k         corr =  0.26  rmse =  0.62  false decisions =  22%  percentiles [ 2.00,25.41,39.46,50.52,82.73]
its4s            corr =  0.01  rmse =  0.77  false decisions =  31%  percentiles [ 4.56,28.19,35.48,42.62,66.35]
AGH-NTIA-Dolby   corr =  0.15  rmse =  1.11  false decisions =  32%  percentiles [11.51,26.53,33.21,41.57,54.11]
vqegHDcuts       corr =  0.02  rmse =  0.89  false decisions =  33%  percentiles [ 7.77,27.19,33.61,42.19,65.54]

average          corr =  0.18  rmse =  0.84
pooled           corr =  0.11  rmse =  0.87  percentiles [ 0.00,28.22,37.57,47.38,90.43]```
![](images/report_nr_iqa_cdi_std.png)


### Entropy ###
The scatter plots have a lower triangle shape (i.e., narrow range of values for high quality, wide range of values for low quality). We expect this shape when the metric detects an impairment that occurs sporadically. Further research would be needed to identify how this information could be used for root cause analysis, as it is not clear what impairment Entropy detects. 
```
3) NR-IQA-CDI entropy 
bid              corr =  0.24  rmse =  0.98  false decisions =  27%  percentiles [ 1.92, 6.53, 7.02, 7.33, 7.66]
ccriq            corr =  0.32  rmse =  0.97  false decisions =  31%  percentiles [ 0.27, 6.37, 6.93, 7.20, 7.70]
cid2013          corr =  0.35  rmse =  0.84  false decisions =  28%  percentiles [-0.00, 6.52, 7.14, 7.44, 7.68]
C&V              corr =  0.31  rmse =  0.68  false decisions =  25%  percentiles [ 2.10, 6.67, 6.96, 7.17, 7.56]
its4s2           corr =  0.24  rmse =  0.72  false decisions =  23%  percentiles [ 2.13, 6.68, 7.11, 7.38, 7.70]
LIVE-Wild        corr =  0.27  rmse =  0.79  false decisions =  24%  percentiles [ 0.94, 6.73, 7.10, 7.35, 7.70]
its4s3           corr =  0.31  rmse =  0.72  false decisions =  22%  percentiles [ 1.50, 6.09, 6.76, 7.15, 7.68]
its4s4           corr =  0.23  rmse =  0.86  false decisions =  26%  percentiles [ 4.25, 6.68, 7.03, 7.28, 7.61]
konvid1k         corr =  0.33  rmse =  0.61  false decisions =  21%  percentiles [ 1.59, 6.04, 6.80, 7.18, 7.69]
its4s            corr =  0.02  rmse =  0.77  false decisions =  30%  percentiles [ 0.20, 6.61, 6.99, 7.24, 7.77]
AGH-NTIA-Dolby   corr =  0.03  rmse =  1.13  false decisions =  35%  percentiles [ 5.46, 6.50, 6.79, 7.11, 7.55]
vqegHDcuts       corr =  0.08  rmse =  0.89  false decisions =  30%  percentiles [ 3.92, 6.45, 6.82, 7.11, 7.61]

average          corr =  0.23  rmse =  0.83
pooled           corr =  0.22  rmse =  0.85  percentiles [-0.00, 6.49, 6.94, 7.26, 7.77]
```
![](images/report_nr_iqa_cdi_entropy.png)

### Skewness
Most media have similar Skewness values, but MOSs that span the full range of MOSs. Note the vertical distribution of data from -0.5 to 0.75. This is a severe problem for metrics that assess overall quality. The remaining data (scattered both above and below the vertical cluster of data) and a small number of outliers strongly influence the correlation and fit. 

Skewness would probably benefit from being clipped. For example, positive Skewness values may indicate a specific impairment.
```
5) NR-IQA-CDI skewness 
bid              corr =  0.16  rmse =  1.00  false decisions =  40%  percentiles [-2.20,-0.19, 0.21, 0.67, 8.51]
ccriq            corr =  0.20  rmse =  1.00  false decisions =  41%  percentiles [-10.66,-0.28, 0.11, 0.90,  NaN]
cid2013          corr =  0.42  rmse =  0.81  false decisions =  50%  percentiles [-1.99,-0.01, 0.29, 0.61,  NaN]
C&V              corr =  0.14  rmse =  0.71  false decisions =  33%  percentiles [-0.98, 0.02, 0.42, 0.74,  NaN]
its4s2           corr =  0.17  rmse =  0.73  false decisions =  35%  percentiles [-3.52,-0.04, 0.36, 0.86,  NaN]
LIVE-Wild        corr =  0.18  rmse =  0.81  false decisions =  38%  percentiles [-2.46,-0.03, 0.37, 0.76,  NaN]
its4s3           corr =  0.20  rmse =  0.72  false decisions =  37%  percentiles [-2.22, 0.25, 0.72, 1.32,  NaN]
its4s4           corr =  0.05  rmse =  0.88  false decisions =  33%  percentiles [-1.75, 0.03, 0.34, 0.77,  NaN]
konvid1k         corr =  0.30  rmse =  0.60  false decisions =  36%  percentiles [-3.68,-0.09, 0.39, 1.00,  NaN]
its4s            corr =  0.00  rmse =  0.77  false decisions =  32%  percentiles [-6.16,-0.00, 0.42, 0.86,  NaN]
AGH-NTIA-Dolby   corr =  0.01  rmse =  1.12  false decisions =  36%  percentiles [-0.70, 0.24, 0.69, 1.12,  NaN]
vqegHDcuts       corr =  0.10  rmse =  0.89  false decisions =  36%  percentiles [-1.58,-0.02, 0.59, 1.16,  NaN]

average          corr =  0.16  rmse =  0.84
pooled           corr =  0.14  rmse =  0.86  percentiles [-10.66,-0.04, 0.42, 0.94,  NaN]
```
![](images/report_nr_iqa_cdi_skewness.png)


### Kurtosis
Most media have Kurtosis values below 5, which is associated with the full range of MOSs (note the vertical distribution of data near zero). This is a severe problem for metrics that assess overall quality (MOS). 

However, Kurtosis shows a lower triangle shape (i.e., narrow range of values for high quality, wide range of values for low quality). We expect this shape when the metric detects an impairment that occurs sporadically and infrequently. Further research would be needed to identify how this information could be used for root cause analysis, as it is not clear what impairment Kurtosis detects. 
```
4) NR-IQA-CDI kurtosis 
bid              corr =  0.15  rmse =  1.00  false decisions =  42%  percentiles [ 1.23, 2.27, 2.81, 3.96,139.39]
ccriq            corr =  0.24  rmse =  0.99  false decisions =  42%  percentiles [ 1.55, 2.57, 3.25, 5.25,  NaN]
cid2013          corr =  0.03  rmse =  0.90  false decisions =  29%  percentiles [ 1.62, 2.05, 2.60, 3.37,  NaN]
C&V              corr =  0.27  rmse =  0.69  false decisions =  34%  percentiles [ 1.23, 1.96, 2.55, 3.10,  NaN]
its4s2           corr =  0.14  rmse =  0.74  false decisions =  34%  percentiles [ 1.21, 2.20, 2.82, 4.11,  NaN]
LIVE-Wild        corr =  0.14  rmse =  0.81  false decisions =  36%  percentiles [ 1.14, 2.20, 2.75, 3.74,  NaN]
its4s3           corr =  0.27  rmse =  0.71  false decisions =  37%  percentiles [ 1.18, 2.84, 3.81, 6.33,  NaN]
its4s4           corr =  0.06  rmse =  0.88  false decisions =  38%  percentiles [ 1.53, 2.67, 3.30, 4.31,  NaN]
konvid1k         corr =  0.21  rmse =  0.62  false decisions =  35%  percentiles [ 1.17, 2.59, 3.34, 5.21,  NaN]
its4s            corr =  0.04  rmse =  0.77  false decisions =  33%  percentiles [ 1.32, 2.57, 3.17, 4.46,  NaN]
AGH-NTIA-Dolby   corr =  0.00  rmse =  1.12  false decisions =  38%  percentiles [ 1.71, 2.75, 3.73, 5.25,  NaN]
vqegHDcuts       corr =  0.07  rmse =  0.89  false decisions =  34%  percentiles [ 1.43, 2.80, 3.71, 5.09,  NaN]

average          corr =  0.14  rmse =  0.84
pooled           corr =  0.14  rmse =  0.86  percentiles [ 1.14, 2.46, 3.17, 4.74,  NaN]
```
![](images/report_nr_iqa_cdi_kurtosis.png)

