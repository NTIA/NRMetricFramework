# Report on S-Blockiness

_This is a self-assessment._

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Function `nrff_blockiness.m` assesses overall blockiness. This algorithm is accurate enough to be included in NR Metric [Sawatch](ReportSawatch.md). 

Goal|Metric Name|Rating
----|-----------|------
RCA|S-Blockiness|:star: :star:

## Algorithm Summary
Function `nrff_blockiness.m` analyzes the angle of small edges in the luma plane, using a (5×5) edge filter. The luma image is split into edges that are extremely close to horizontal or vertical (HV), and the remaining edges (HVbar). Put simply, blockiness triggers if the entire image has higher than expected HV edge energy, relative to the HVbar edge energy. There are correction factors to avoid falsely penalizing areas with low edge energy, intentional horizontal and vertical edges, and random fluctuations in edge angle.

The edge filter is a variant of the Sobel filter that was developed by NTIA to detect larger edges than the popular (3×3) edge filters (e.g., Sobel, Laplacian). See function `filter_si_hv_adapt.m`.

## Speed and Conformity

Blockiness runs roughly __1.15×__ slower than the benchmark metric, [nrff_blur.m](ReportBlur.md).

In Big-O notation, Blockiness is O(n). 

Function `nrff_blockiness.m` was initially provided by this repository, so conformity is ensured. 

## Analysis

This analysis uses three types of datasets:
* Image quality datasets with camera impairments (BID, CCRIQ, CID2013, C&V, ITS4S2, ITSnoise, and LIVE-Wild)
* Video quality datasets with camera impairments (ITS4S3, ITS4S4, KonViD-1K, and KoNViD-150K-B)
* Video quality datasets with broadcast content and compression (ITS4S, AGH-NTIA-Dolby, vqegHD, and YoukuV1K) 

S-Blockiness emphasizes avoiding type 1 errors (false positives). Parameter levels are very low for all camera quality datasets and ITS4S, which do not contain blocking artifacts. The outlier in dataset KonViD-1K is computer generated abstract art that looks similar to blocking artifacts. The rate of type 2 errors (false negatives) is higher, so this RCA parameter may miss subtle blocking artifacts. 

Only datasets AGH-NTIA-Dolby and vqegHD contain obvious blocking artifacts. Their blockiness scatter plots have a lower triangle shape (i.e., narrow range of values for high quality, wide range of values for low quality). We expect this shape when an impairment occurs sporadically.  

The overall performance is promising. More datasets with blocking artifacts would be needed to better assess performance. 
```text
1) S-Blockiness 
bid              corr =  0.058  rmse =  1.01  false decisions =  55%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.03]
ccriq            corr =  0.156  rmse =  1.01  false decisions =  68%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.10]
cid2013          corr =  0.099  rmse =  0.90  false decisions =  57%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.04]
C&V              corr =  0.253  rmse =  0.69  false decisions =  85%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.00]
its4s2           corr =  0.067  rmse =  0.74  false decisions =  43%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.05]
ITSnoise         corr =  0.002  rmse =  0.80  false decisions =  30%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.00]
LIVE-Wild        corr =  0.153  rmse =  0.81  false decisions =  37%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.10]
its4s3           corr =  0.447  rmse =  0.68  false decisions =  48%  percentiles [ 0.00, 0.00, 0.00, 0.01, 0.12]
its4s4           corr =  0.041  rmse =  0.88  false decisions =  33%  percentiles [ 0.00, 0.00, 0.00, 0.01, 0.15]
konvid1k         corr =  0.179  rmse =  0.63  false decisions =  39%  percentiles [ 0.00, 0.00, 0.00, 0.01, 0.64]
KoNViD-150K-B    corr =  0.248  rmse =  0.58  false decisions =  39%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.22]
its4s            corr =  0.088  rmse =  0.77  false decisions =  43%  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.02]
AGH-NTIA-Dolby   corr =  0.537  rmse =  0.95  false decisions =  60%  percentiles [ 0.00, 0.00, 0.01, 0.04, 0.95]
vqegHD           corr =  0.529  rmse =  0.76  false decisions =  51%  percentiles [ 0.00, 0.00, 0.01, 0.03, 0.47]
YoukuV1K         corr =  0.315  rmse =  0.86  false decisions =  49%  percentiles [ 0.00, 0.01, 0.02, 0.05, 0.62]

average          corr =  0.211  rmse =  0.80
pooled           corr =  0.203  rmse =  0.82  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.95]
```
![](images/report_blockiness.png)


