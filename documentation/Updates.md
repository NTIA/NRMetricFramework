# Updates to NR Metric Framework Repository

Please download this repository from the [releases page](https://github.com/NTIA/NRMetricFramework/releases).
This updates our download count, which helps us quantify the value of this repository.

This page has release notes and identifies updates that will change the code's behavior.

## NR Metric Framework Version 3.0

The third release of the NR Metric Framework includes the following changes:

- NR metric Sawatch Version 3.0
- The NR metrics that feed into Sawatch have names prefixed with 'S-' 
- [New datasets](SubjectiveDatasets): KonIQ10k, KoNViD-150K-B, MUI2018, VCRDCI, vqegHD, and YoukuV1K 
- Most [Reports](Reports.md) analyze NR metrics on 6 IQA datasets (previously available) and 6 VQA datasets (new). Our star ratings and analyses were updated to reflect this extra information. 
- New function [ci_NRpars.m and ci_calc.m](ConfidenceIntervals.md) 
- New function [peek_NRpars.m](PeekNRpars.md) 
- New function [update_NRpars.m](UpdateNRpars.md)
- Bug fixes
- Changed dataset field 'test' to 'dataset_name' to avoid confusion when debugging

__Warning:__ This release changes the field name 'test' to 'dataset_name'. 
This change impacts all NRpars and all dataset variables.
If you have NR parameter data saved, you must run the [update_NRpars.m](UpdateNRpars) function to fix NRpars.mat files. 
Alternatively, you can erase the NRpars files and recalculate from features, but this will be unnecessarily slow.
See also [Demo1](Demo1.md).

## NR Metric Framework Version 2.0
The second release of the NR Metric Framework includes the following changes:

- NR Metric Sawatch Version 2.0
- Confidence intervals for quality metrics
- Directory "documents" contains help (previously Wiki files)
- Documentation includes performance reports for NR metrics
- Directory "reports" contains code for 6 NR metrics from other organizations
- Bug fixes

## NR Metric Framework Version 1.0
The first release of the NR Metric Framework contained the initial release of this repository.
