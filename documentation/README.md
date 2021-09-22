## Welcome 

Welcome to the NRMetricFramework documentation! This directory provides function documentation for the NRMetricFramework GitHub repository.

## Overview

**No-reference (NR) metrics** are algorithms that predict the quality of an image or video, using only the pixel values. This repository takes an inclusive philosophy. We want to also support metrics that analyze some information from **compressed bit-streams**, but the necessary support functions are not yet implemented.

This repository does not contain images and videos. See the [subjective datasets](SubjectiveDatasets.md) page for information on where to download suitable datasets.

## Tutorials / Demos 
- [Demo #1](Demo1.md) — get started
- [Demo #2](Demo2.md) — code NR parameters
- [Demo #3](Demo3.md) — train NR metrics

## References
- [Dataset Structure](DatasetStructure.md) — variables that describe subjective datasets
- [Publications](Publications.md) — papers that describe this repository 
- [Subjective Datasets](SubjectiveDatasets.md) — list of subjective datasets for no reference metric research
- [Wishlist](Wishlist.md) — future capabilities that are desired but not yet implemented

## Main Functions
- [analyze_NRpars.m](AnalyzeNRpars.md)
- [import_dataset.m](ImportDataset.md)
- [calculate_NRpars.m](CalculateNRpars.md)
- [compromise_NRpars.m](CompromiseNRpars.md)
- [ci_NRpars.m and ci_calc.m](ConfidenceIntervals.md) - new!
- [peek_NRpars.m](PeekNRpars.md) - new!

## Exporting Functions
- [export_dataset.m](ExportDataset.md)
- [export_NRpars.m](export_NRpars.md)

## Media Functions 
- [convert_media.m](ConvertMedia.md) — convert videos to uncompressed AVI
- [display_xyt.m and display_color_xyt.m](DisplayImage.md) — shown an image or video
- [read_avi.m](ReadAvi.md) — read an uncompressed AVI file
- [read_media.m](ReadMedia.md) — read a dataset's media
- [rgb2ycbcr_double.m](rgb2ycbcr_double.md) — color space conversion: RGB to YCbCr
- write_avi.m — write a video to an uncompressed AVI file
- ycbcr2rgb_double.m — color space conversion: YCbCr to RGB

## Image Processing Functions
- [divide_100_blocks.m](Divide100Blocks.md) — specify 100 regions, roughly equal in size
- filter_sobel.m — Sobel filter
- filter_si_hv_adapt.m — large edge [spatial information (SI) filter](https://www.its.bldrdoc.gov/resources/video-quality-research/guides-and-tutorials/spatial-information-si-filter.aspx)
- filter_smooth.m — bandpass filter with characteristics similar to SI filter used by filter_si_hv_adapt.m
- image_scale.m — scale image to monitor used during subjective test
- [st_statistic.m](STstatistic.md)
- [valid_region_search_nosafety.m](ValidRegionSearchNoSafety.md)

## Subjective Test Analysis
- [analyze_lab2lab.m](AnalyzeLb2Lab.md)

## NR Metrics and Reports 
This repository includes (1) code for NR metrics developed by various organizations, and (2) reports that analyze their performance. 
This [introduction](Report.md) defines the :star: :star: :star: :star: :star: scale used in the reports and tables below. 
Generally, 1-star metrics are very innacurate, 
2-star metrics are promising, 
3-star metrics perform consistently across 10+ datasets,
4-star metrics are as accurate as one person, and
5-star metrics are as accurate as a 6 person pilot test.

### Our NR Metrics 

The [Sawatch](ReportSawatch.md) NR metric was developed by NTIA using the NRMetricFramework repository. Sawatch estimates mean opinion score (MOS) via a linear combination of other NR metric parameters that supply root cause analysis (RCA). An online demo of Sawatch version 2 is available [here](https://vqwt.its.bldrdoc.gov/login.php).

Metric Name|Goal|[Rating](Report.md)|Notes
-----------|----|------|-----
[Sawatch](ReportSawatch.md) version 2|MOS|:star: :star: :star:|NR metric training method demonstrated
[Sawatch](ReportSawatch.md) version 1|MOS|:star: :star:|NR metric training method demonstrated

Metric Name|Metric Group|Goal|[Rating](Report.md)
-----------|------------|----|------
White Level|[Auto Enhancement](ReportAutoEnhancement.md)|RCA|:star: :star: :star:
Black Level|[Auto Enhancement](ReportAutoEnhancement.md)|RCA|:star: :star:
Blockiness|[Blockiness](ReportBlockiness.md)|RCA|:star: :star:
Unsharp|[Blur](ReportBlur.md)|RCA|:star: :star: :star:
Viqet-Sharpness|[Blur](ReportBlur.md)|RCA|:star: :star: :star:
Fine Detail|[Fine Detail](ReportFineDetail.md)|RCA|:star: :star: :star:
PanIPS|[Pan Speed](ReportPanIPS.md)|RCA|:star: :star:
Color Noise|[Peculiar Color](ReportPeculiarColor.md)|RCA|:star: :star:
Super Saturation|[Peculiar Color](ReportPeculiarColor.md)|RCA|:star: :star:
Pallid|[Peculiar Color](ReportPeculiarColor.md)|RCA|:star: :star:

### Other Organizations' NR Metrics

The following pages provide objective and factual information on the performance of NR metrics from other organizations. These reports analyze the metric's performance on diverse media from modern camera systems. This is often outside of the metric's intended scope. See [Introduction](Report.md) for details. 

Metric Name|Goal|[Rating](Report.md)|Notes
-----------|----|------|------
[2stepQA-NR](Report2stepQA.md)|MOS|:star: :star: |NR constrained variant of 2stepQA, outliers and invalid values prevent :star: :star: :star: rating
[BRISQUE](ReportBrisque.md)|MOS|:star:| 
[Curvelet QA](ReportCurveletQA.md)|MOS|:question:|4 variants, technical issues mar performance and prevent analyses
[JP2KNR](ReportJP2KNR.md)|MOS|:star:|Code produces errors, content dependencies, possible inspiration for RCA 
[LBP](ReportLBP.md)|MOS|:star:|Not intended for MOS estimation, possible inspiration for RCA
[Log-BIQA](ReportLogBiqa.md)|MOS|:star:|
[NIQE](ReportNiqe.md)|MOS|:star: :star:|Re-training tools available
[NR-IQA-CDI](ReportNRIQACDI.md)|MOS|:star:|Variants Mean, Standard deviation, and Skewness
[NR-IQA-CDI](ReportNRIQACDI.md)|MOS|:star: :star:|Variants Kurtosis and Entropy: possible inspiration for RCA
[NSS](ReportNSS.md)|MOS|:star:|3 variants, outliers mar performance
[OG-IQA](ReportOGIQA.md)|MOS|:star: :star:|Partial analysis, possible inspiration for RCA
[PIQE](ReportPIQE.md)|MOS|:star:|
[SpEED-NR](ReportSpEED.md)|MOS|:star: :star:|NR constrained variant of Speed-QA, outliers mar performance

Metric Name|Goal|[Rating](Report.md)|Impairment|Notes
-----------|----|------|---------|------
[ADMD](ReportADMD.md)|RCA|:star:|Uneven illumination| 
[AGWN](ReportAGWN.md)|RCA|:star:|Noise|
[CPBD](ReportCPBD.md)|RCA|:star: :star:|Blur/Sharpness|
[Entropy_Noise](ReportEntropyNoise.md)|RCA|:star:|Noise|
[HVS-MaxPol](ReportHVSMaxPol.md)|RCA|:star: :star:|Blur/Sharpness|4 variants, trained on 7 datasets, outliers prevent :star: :star: :star: rating
[JNB](ReportJNB.md)|RCA|:star: :star:|Blur/Sharpness|Performance marred by resolution dependencies 
[MaxPol](ReportMaxPol.md)|RCA|:star: :star:|Blur/Sharpness|Aka Synthetic-MaxPol, invalid values prevent :star: :star: :star: rating
[NR-PWN](ReportNRPWN.md)|RCA|:star: :star:|Noisiness|Performance marred by dataset dependencies
[TDME](ReportTdme.md)|RCA|:star: :star: :star:|Contrast enhancement|
[TDMEC](ReportTdmec.md)|RCA|:star: :star: :star:|Contrast enhancement|


Metric Name|Goal|[Rating](Report.md)|Notes
-----------|----|------|------
[dipIQ](ReportDipIQ.md)|ORD|:star: :star:|NR metric training method, statistics for ORD proposed


## Acknowledgements

If you use this repository in your research or product development, please reference this GitHub repository and the paper listed below:

> Margaret H. Pinson, Philip J. Corriveau, Mikołaj Leszczuk, and Michael Colligan, ["Open Software Framework for Collaborative Development of No Reference Image and Video Quality Metrics,"](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3249) _Human Vision and Electronic Imaging (HVEI)_, Jan. 2020.

The first version of the code in this repository was designed and made available by:
* The Institute for Telecommunication Sciences (ITS), which is the research and engineering branch of the National Telecommunications and Information Administration (NTIA), an agency of the U.S. Department of Commerce (DOC)
* The Public Safety Communications Research (PSCR) Division of the National Institute for Standards and Technology (NIST), an agency of the U.S. Department of Commerce (DOC)

This repository was inspired by discussions and work conducted in the Video Quality Experts Group ([VQEG](https://www.its.bldrdoc.gov/vqeg/vqeg-home.aspx)), especially the efforts of the No Reference Metrics (NORM) project and the Video and Image Models for consumer content Evaluation (VIME) project.
