# NR Metric Reports

These NR metric reports are intended to support an open exchange of ideas, information, and research. To develop NR metrics, we need objective and factual information on the performance of NR metrics. Developers need this information to make the best decisions on where to focus future research. Industry needs this information to trust and deploy NR metrics.

## Warning
 
* Algorithm discrepancies may occur (e.g., we misunderstand the publication) 
* We do not retrain machine learning algorithms 
* We do not limit our analyses to the NR metric's intended scope
* Our performance assessments include diverse media from modern camera systems
* We do not check whether root cause analysis metrics detect the intended impairment

Authors are encouraged to send feedback, corrections, and NR metric code to Margaret Pinson, NTIA/ITS <mpinson@ntia.gov>

## Sections

Each report contains the following sections:

* Introduction — overall performance assessment  
* Algorithm Summary — short description of the metric
* Speed and Conformity — run speed, how well this implementation matches the reference
* Analysis — statistical analysis and our interpretation

The introduction provides a reference, describes the metric's goal (what it computes or analyzes), summarizes the metric's performance, and rates the metric's overall performance for modern camera systems. 

The report contains two estimates of the NR metric's speed. First, we provide the algorithm's Big-O notation. Second, the NR metric's run speed is compared to the baseline metric, [nrff_bur.m](ReportBlur.md). This relative estimate may not be helpful if the author is unskilled at programming in MATLAB®.  

Reports for high performing NR metrics will also contain a section, Confidence Interval, that uses the techniques presented in [[7]](Publications.md) to report metric precision and likelihood of errors during decision making. 


### Metric Goal and Rating
NR metrics are classified by their goal and rated on a 5-level scale (see tables below). The metric goal influences our interpretation of the statistics and scatter plots. Most of our datasets contain multiple impairments, so root cause analysis (RCA) metrics will naturally have worse statistics than MOS metrics. 

Some metrics attempt to order media by quality discriminability (ORD). Approaches for calculating the truth data include quality-discriminable image pairs (DIP) using full reference (FR) metric assessment [[12]](Publications.md) and just noticeable difference (JND) subjective testing. The targets of these models differ (e.g., to assess MOS without subjective tests, to predict JND, or to discern the optimal set of compression parameters for a source video). The statistics we use (described below) are ill suited to analyze these metrics.

__R&D Potential__ notes techniques of potential use for future NR metric R&D (e.g., training method, statistical analysis technique, or the potential for improved metric performance if a defect is fixed). 

Analysis|Goal|Abbreviation
--------|----|------------
assess overall quality|mean opinion score|MOS
assess one impairment|root cause analysis|RCA 
rank order media by quality|comparisons|ORD


Rating Scale for MOS|Definition
------------|----------
:question:|Technical issues prevent analyses
:star:|Very inaccurate 
:star: :star:|Promising results 
:star: :star: :star:|Consistent performance for 10+ datasets. Valid for all media. Equivalent to one person ad-hoc test for 1+ dataset
:star: :star: :star: :star:|As accurate as a one person ad-hoc test across 10+ datasets 
:star: :star: :star: :star: :star:|As accurate as a six person pilot test across 10+ datasets 

Rating Scale for RCA|Definition
------------|----------
:question:|Technical issues prevent analyses
:star:|Very inaccurate 
:star: :star:|Promising results 
:star: :star: :star:|Consistent performance for 10+ datasets. Valid for all media. 
:star: :star: :star: :star:|To be determined 
:star: :star: :star: :star: :star:|To be determined 

Note: we are still establishing objective criteria for high performing RCA metrics. 

See [[7]](Publications.md) and [confidence intervals](ConfidenceIntervals.md) for information on how we evaluate whether a metric is equivalent to a one person ad-hoc test or a six person pilot test. 

### Statistics and Scatter Plots

The statistics and scatter plots are produced by [analyze_NRpars.m](AnalyzeNRpars.md). All MOSs are scaled to [1..5] for consistent presentation. "Corr" indicates Pearson correlation. "RMSE" indicates root mean squared error. Percentiles are 0%, 25%, 50%, 75%, and 100%. The statistics will include not-a-number (NaN) when the metric produces invalid results for some media. These missing values are ignored when calculating RMSE and Pearson correlation. 

Each report includes scatter plots that depict the NR metric's response for each subjective dataset (blue dots) within the context of the other datasets presented (green dots). The latter shows the general relationship between the metric and MOS. The scatter plots show the NR metric on the x-axis and MOS on the y-axis. A red line shows the linear fit for the current dataset. These plots are produced by [analyze_NRpars.m](AnalyzeNRpars.md), using subjective datasets that were [selected for NR metric research](SubjectiveDatasets.md). These analyses use the 90% of media that are reserved for [training metrics](DatasetStructure.md), because these reports are part of a larger effort to train robust NR metrics. 

More information on the datasets used to analyze NR metrics can be found [here](DatasetStructure.md) and [here](SubjectiveDatasets.md).

### Code
Each report is associated with code that implements the NR metric. If the metric was developed by another organization, then code implementing the metric is provided in the "reports" sub-directory of the NRMetricFramework. NR metrics that are integral to this repository are located in the NRMetricFramework's top-level directory. 


