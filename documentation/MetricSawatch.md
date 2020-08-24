# MATLAB Function `metric_sawatch.m`

We propose NR metric Sawatch version 1 as the basis for a series of NR metrics that provide RCA. The intention is that Sawatch will be updated regularly instead of remaining a fixed, static algorithm.

"Sawatch" is a mountain range in Colorado, USA, that includes 8 of the 20 tallest mountain peaks in the Rocky Mountains.
We suggest this name for a family of NR metrics as analogy for collaboration.
We tackle a difficult task, where we hope to produce NR metrics with higher and higher accuracy. 

## SYNTAX
The standard NR metric interface is specified on the [calculate_NRpars.m](CalculateNRpars.md) page. Scroll down to the section **"Variant NR Feature Function Interface for NR Metrics."**

## Usage
The `metric_sawatch.m` code also provides an example illustrating how to write a metric function that is compatible with the analysis functions [analyze_NRpars.m](AnalyzeNRpars.md) and [compromise_NRpars.m](CompromiseNRpars.md). 

The expected workflow is as follows:
1. Develop and calculate NR parameters 
2. Train an NR metric 
3. Write an NR metric 
4. Calculate the NR metric
5. Analyze the NR metric using [analyze_NRpars.m](AnalyzeNRpars.md) and [compromise_NRpars.m](CompromiseNRpars.md)
6. Code the NR metric with a different programming language, to deploy to users

The data flow is: images / videos --> NR features --> NR parameters --> NR metric. 

NR metrics can be calculated by using either the 'compose' mode or [calculate_NRpars.m](CalculateNRpars.md).

## Details
### Satatch Version 1
NR metric Sawatch is provided as a starting point for collaboratively developed NR metrics for consumer camera applications. Known faults include:
* Low accuracy
* Fails to account for the difference between MOSs from consumer camera images and videos
* RCA unavailable for [many impairments](https://docs.google.com/spreadsheets/d/1A9pJd0RR1ZrvcmU_B9XuF6okQkq9nFlDekJWp-cq3Fo/edit#gid=0) (e.g., noise, compression, ringing, interlace).

Sawatch Version 1 is reported on a [5..1] scale. Three NR parameters provide RCA:
* White Level — is the media is too dark?
* Sharpness — is the most in-focus region of the media is too blurry?
* PanIPS — does the camera move too quickly?

**WhiteLevel** from `nrff_auto_enhancement.m` considers only the luma plane (Y.md) and only penalizes media when the 98th percentile drops below 150. This threshold was chosen based on [subjective datasets](SubjectiveDatasets.md) BID, CCRIQ, CID2013_dataset, ITS4S2, ITS4S3, and Live Wild.

**Blur** combines quality estimations from two algorithms from `nrff_blur.m`. The first is based on the unsharp filter and finds the sharpest areas of an image by dividing the image into [100 blocks](Divide100Blocks.md). The second uses the Laplacian filter, as proposed by the VQEG Image Quality Evaluation Tool ([VIQET](https://github.com/VIQET.md).md), and finds the sharpest areas of an image overall, on a pixel-by-pixel basis. Both algorithms perform similarly. 

**PanSpeed** from `nrff_PanIPS.m` was trained on the ITS4S4 dataset, which contains only camera pans. **PanSpeed** only considers the overall motion of the camera. **PanSpeed** may be inaccurate when given videos that contain complex motion (e.g., two large objects moving different directions). IPS refers to the speed of the pan, measured in images per second. 

**Sawatch** version 1 scales each NR parameter to [0..1], calculates the overall NR metric, and saves all data as per NR parameters. 
The form of the Sawatch metric is a linear equation of the form:
     MOS = 5 - wt(1) * par1 - wt(2) * par2 - wt3 * par(3)
Where par1, par2, and par3 are **WhiteLevel**, **Blur**, and **PanSpeed** respectively. Each of three parameter is also reported separately, to provide RCA. 
A user who wants to ignore the impact of a particular impairment can simply set that parameter's weight to zero. 
As an example, broadcasters may wish to ignore **WhiteLevel** (e.g., the artist intentionally created a very dark movie scene).
