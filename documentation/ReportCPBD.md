# Report on Cumulative Probability of Blur Detection (CPBD)

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Function `nrff_CPBD.m` implements the cumulative probability of blur detection (CPBD) metric, as presented in [[18]](Publications.md). The goal is to detect blur and sharpness.  

Goal | Metric Name|Rating
-----|------------|------
RCA  | CPBD | :star: :star:

## Algorithm Summary
The algorithm performs edge detection and divides the image into blocks. Once the blocks are determined, the algorithm checks the number of edge pixels and determines if the block is a smooth block or an edge block. If it is a smooth block, the block is discarded and not processed, otherwise the block gets processed as follows. The overall contrast with just-noticeable-blur (JNB) is calculated. Each edge is then analyzed and a value for the edge width is generated. The blur probability for each is calculated by taking one minus e to the power of the negative value of edge width divided by the JNB width taken to the power of a predetermined constant beta. In the provided code, beta is defined as 3.6. Lastly, the CPBD sharpness metric is calculated by the sum of the blur probabilities that are less than the just-noticeable-blur probability.

## Speed and Conformity
CPBD took __3×__ as long to run as the benchmark metric, [nrff_blur.m](ReportBlur.md).

In Big-O notation, CPBD is O(n). 

In terms of conformity, the author's code is used with the exception of one area where the floor function is used to guarantee an integer for indexing purposes with `CPBD_compute.m`.

## Analysis
The authors report 0.9071 Pearson correlation between CPBD and MOS for a private image quality dataset. 

This report evaluates CPBD using six image quality datasets that contain camera impairments. The correlations are low but sufficiently high to be promising as an RCA parameter. However, the scatter plot distributions are fairly random with a mild positive trend. Compare the scatter of blue dots (for the current dataset) with the green dots (that show the overall response of all dataset. 
```
--------------------------------------------------------------
1) CPBD
bid              corr =  0.15  rmse =  1.00  percentiles [ 0.01, 0.23, 0.41, 0.54, 0.96]
ccriq            corr =  0.32  rmse =  0.97  percentiles [ 0.01, 0.37, 0.53, 0.68, 0.95]
cid2013          corr =  0.27  rmse =  0.87  percentiles [ 0.00, 0.54, 0.64, 0.71, 1.00]
C&V              corr =  0.24  rmse =  0.70  percentiles [ 0.12, 0.52, 0.64, 0.70, 0.79]
its4s2           corr =  0.20  rmse =  0.73  percentiles [ 0.01, 0.43, 0.57, 0.68, 0.95]
LIVE-Wild        corr =  0.41  rmse =  0.75  percentiles [ 0.01, 0.43, 0.58, 0.68, 0.91]

average          corr =  0.27  rmse =  0.83
pooled           corr =  0.23  rmse =  0.86  percentiles [ 0.00, 0.41, 0.56, 0.68, 1.00]
```
![](images/report_CPBD.png)
