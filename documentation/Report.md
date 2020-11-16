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

* Introduction — overall performance assessment  
* Algorithm Summary — short description of the metric
* Speed and Conformity — run speed, how well this implementation matches the reference
* Analysis — statistical analysis and our interpretation

The introduction provides a reference, describes the metric's goal (what it computes or analyzes), summarizes the metric's performance, and rates the metric's overall performance for modern camera systems. 

Reports for high performing NR metrics will also contain a section, Confidence Interval, that uses the techniques presented in [[7]](Publications.md) to report metric precision and likelihood of errors during decision making. 


### Metric Goal and Rating
NR metrics are classified by their goal and rated on a 4-level scale (see tables below). The metric goal influences our interpretation of the statistics and scatter plots. Most of our datasets contain multiple impairments, so root cause analysis (RCA) metrics will naturally have worse statistics than MOS metrics.

Goal|Target|Abbreviation
----|------|------------
assess overall quality|mean opinion score|MOS
assess one impairment|root cause analysis|RCA 

Rating Scale|Definition
------------|----------
:star:|The metric is very inaccurate 
:star: :star:|The metric yields promising results 
:star: :star: :star:|The metric has consistent performance across 10+ datasets
:star: :star: :star: :star:|The metric is as accurate as a one person ad-hoc test across 10+ datasets [[7]](Publications.md)
:star: :star: :star: :star: :star:|The metric is as accurate as a six person pilot test across 10+ datasets [[7]](Publications.md)

### Statistics and Scatter Plots

Each report includes scatter plots that depict the NR metric's response for each subjective dataset (blue dots) within the context of the other datasets presented (green dots). The latter shows the general relationship between the metric and MOS. The scatter plots show the NR metric on the x-axis and MOS on the y-axis. A red line shows the linear fit for the current dataset. These plots are produced by [analyze_NRpars.m](AnalyzeNRpars.md), using subjective datasets that were [selected for NR metric research](SubjectiveDatasets.md). These analyses use the 90% of media that are reserved for [training metrics](DatasetStructure.md), because these reports are part of a larger effort to train robust NR metrics. 

More information on the datasets used to analyze NR metrics can be found [here](DatasetStructure.md) and [here](SubjectiveDatasets.md).

### Code
Each report is associated with code that implements the NR metric. If the metric was developed by another organization, then code implementing the metric is provided in the "reports" sub-directory of the NRMetricFramework. NR metrics that are integral to this repository are located in the NRMetricFramework's top-level directory. 
