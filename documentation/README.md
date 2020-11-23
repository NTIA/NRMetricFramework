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

## NR Metrics and Reports 
- [Introduction](Report.md) to NR metric code and their performance reports
- [List of metrics](ListMetrics.md)

The following NR metric was developed by NTIA using the NRMetricFramework repository.  
- [Sawatch](ReportSawatch.md)

Sawatch calls on the following groups of NR metric parameters, which supply root cause analysis (RCA):
- [Auto Enhancement](ReportAutoEnhancement.md)
- [Blockiness](ReportBlockiness.md)
- [Blur](ReportBlur.md)
- [Fine Detail](ReportFineDetail.md)
- [Pan Speed](ReportPanIPS.md)
- [Peculiar Color](ReportPeculiarColor.md)

The following pages provide objective and factual information on the performance of NR metrics from other organizations: 
- Additive Gaussian White Noise ([AGWN](ReportAGWN.md))
- [Basic Statistics](ReportBasicStats.md) 
- Blind / Referenceless Image Spatial Quality Evaluator [BRISQUE](ReportBrisque.md)
- [Log-BIQA](ReportLogBiqa.md)
- Natural Image Quality Evaluator [NIQE](ReportNiqe.md)
- [Uneven Illumination](ReportUnevenIllumination.md)

 
## Acknowledgements

If you use this repository in your research or product development, please reference this GitHub repository and the paper listed below:

> Margaret H. Pinson, Philip J. Corriveau, Mikołaj Leszczuk, and Michael Colligan, ["Open Software Framework for Collaborative Development of No Reference Image and Video Quality Metrics,"](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3249) _Human Vision and Electronic Imaging (HVEI)_, Jan. 2020.

The first version of the code in this repository was designed and made available by:
* The Institute for Telecommunication Sciences (ITS), which is the research and engineering branch of the National Telecommunications and Information Administration (NTIA), an agency of the U.S. Department of Commerce (DOC)
* The Public Safety Communications Research (PSCR) Division of the National Institute for Standards and Technology (NIST), an agency of the U.S. Department of Commerce (DOC)

This repository was inspired by discussions and work conducted in the Video Quality Experts Group ([VQEG](https://www.its.bldrdoc.gov/vqeg/vqeg-home.aspx)), especially the efforts of the No Reference Metrics (NORM) project and the Video and Image Models for consumer content Evaluation (VIME) project.
