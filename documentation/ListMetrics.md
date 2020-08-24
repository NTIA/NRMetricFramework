# List of No Reference Parameters and Metrics

This page identifies the NR parameters and NR metrics currently available in this repository. 

***

## NR Metrics

### Sawatch
Function [metric_sawatch.m](MetricSawatch.md) is provided as the basis for a series of NR metrics that provide RCA. The intention is that Sawatch will be updated regularly instead of remaining a fixed, static algorithm.


***

## NR Parameters

### Contrast

Function `nrff_auto_enhancement.m` calculates NR features and NR parameters that assess the white level (based on the luma plane) and overall contrast variability (using the RGB color space).
- Attribution: Margaret H. Pinson, NTIA/ITS

### Blurring
Function `nrff_blur.m` parameter 'unsharp' uses the unsharp filter to analyze the sharpness or blurriness, based on the most in-focus areas of the image or video. Intentional blur is common for background areas, so this assessment uses best-case assessments that focus on the sharpest areas spatially. 
- Attribution: Margaret H. Pinson, NTIA/ITS

Function `nrff_blur.m` parameter 'viqet-sharpness' uses the laplacian filter to analyze the sharpness or blurriness, based on the most in-focus areas of the image or video. Function `nrff_viqet.m` took as a starting point for metric development the the VQEG Image Quality Evaluation Tool ([VIQET](https://github.com/VIQET)), algorithm "sharpness3." Function `nrff_viqet.m` contains unused code for Kullback-Leibler divergence, which was used by a VIQET algorithm that was implemented but not developed further. 
- Attribution: Margaret H. Pinson, NTIA/ITS
- Attribution: Intel

The 'Blur' parameter in Sawatch is a weighted average of 'unsharp' and 'viqet-sharpness'.

### Pan Speed
Function `nrff_PanIPS.m` was trained on the ITS4S4 dataset to detect the fall in quality associated with too-fast camera pans. PanIPS only considers the overall motion of the camera. PanIPS may be inaccurate when given videos that contain complex motion (e.g., two large objects moving different directions). IPS refers to the speed of the pan, measured in images per second.
- Attribution: Sam Elting and Margaret H. Pinson, NTIA/ITS
