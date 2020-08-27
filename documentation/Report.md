# NR Metric Reports

These NR metric reports are intended to support an open exchange of ideas, information, and research. To develop NR metrics, we need objective and factual information on the performance of NR metrics. Developers need this information to make the best decisions on where to focus future research. Industry needs this information to trust and deploy NR metrics.

## Warning
 
* Algorithm discrepancies may occur (e.g., we misunderstand the publication) 
* We do not retrain machine learning algorithms 
* We do not limit our analyses to the NR metric's intended scope
* Our performance assessments include diverse media from modern camera systems

Authors are encouraged to send feedback, corrections, and NR metric code to Margaret Pinson, NTIA/ITS <mpinson@ntia.gov>

## Sections

Each report contains the following sections:

* Goal — what the metric computes or analyzes
* Reference — publication, NR metric function 
* Algorithm Summary — short description of the metric
* Speed and Conformity — run speed, how well this implementation matches the reference
* Statistics — our analysis of the metric

We begin with text that summarizes the metric's performance. This text is followed by statistics and plots from function analyze_NRpars.m. Metrics that analyze spatial impairments are only analyzed on image quality datasets. Metrics that analyze temporal impairments are analyzed on video quality datasets. Metrics that analyze both spatial and temporal impairments are analyzed on both image and video quality datasets.

The scatter plots show the NR metric on the x-axis and MOS on the y-axis. Each scatter plot plots one dataset as blue dots. Data from all datasets are plotted as green dots. The latter shows the general relationship between the metric and MOS. The fit between the current dataset (metric versus MOS) is drawn as a red line. The equation is given above the plot. 