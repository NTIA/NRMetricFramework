# Report on the VCRDCI Dataset

_This is a self-assessment._

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

_Go to the [Subjective Datasets](SubjectiveDatasets.md) page for a summary of VCRDCI and other datasets._ 

This report analyzes the VCRDCI dataset. We use the observed performance of [Sawatch version 3](ReportSawatch.md) to gain insights.

## Dataset Summary

VMAF Compression Ratings that Disregard Camera Impairments (VCRDCI) dataset uses [VMAF](https://github.com/Netflix/vmaf) to create simulated MOSs.
VMAF is a full reference (FR) metric that uses machine learning to estimate MOSs by comparing original and compressed versions of the same video.
VMAF is intended for the codec comparison use case (e.g., compare the visual impact of alternative compression settings).

FR metrics assume that the impaired video is supposed to look like the original video.
Any deviation from the original video constitutes a drop in quality. 
FR metrics are usually trained only on high quality original videos, and impairments in the original video are ignored. 

The VCRDCI dataset breaks this rule by using low quality originals with camera capture impairments and low quality videography (e.g., too fast pans).
We intentionally included low quality original videos in VCRDCI. 
Our analysis indicates that VMAF yielded reasonable MOSs for these scenes.

The VCRDCI dataset has a full matrix experiment design with resolutions and bitrates used by adaptive bitrate services.
This dataset is intended as training data for an NR metric that analyzes compression impairments but ignores camera impairments.
The dataset contains 130 original videos. 
The impairments, three codecs (H.264, H.265, and AV1), 8 resolutions, and 10 compression levels for a total of 240. 

The VCRDCI dataset is split into three pieces due to its extremely large size.
- Variable `vcrdci_1_datset` contains part 1 (10,800 files)
- Variable `vcrdci_2_datset` contains part 2 (10,800 files)
- Variable `vcrdci_3_datset` contains part 3 (9,600 files)

## Sawatch Version 3
We will use NR metric [Sawatch](ReportSawatch.md) Version 3 to demonstrate characteristics of the VCRDCI dataset. 
Calculations are currently underway, to enable this analysis. 


