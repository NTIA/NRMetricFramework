# Demo 3: Export Parameters, Calculating Metrics

This page demonstrates workflow options to train an NR metric:

* **Option 1:** export data to simple MATLAB variables (matrices)
* **Option 2:** export data to a spreadsheet
* **Option 3:** understand dataset differences using [compromise_NRpars.m](CompromiseNRpars.md)
* **Option 4:** implement a specific metric, as per [metric_sawatch.m](MetricSawatch.md) 

## Preliminaries

This demo assumes that you have already gone through [Demo #1](Demo1.md) and [Demo #2](Demo2.md).

The NR parameters for this demo are available in `demo2.zip`, which should be unzipped into directory `C:\nr_data\`. The NR features are not provided, for space considerations. 

## Option 1. Export Data to Spreadsheet

Let us begin by calculating two parameters for the CCRIQ dataset. We will use **nrff_panIPS** and **nrff_blur**, which calculate features based on camera pan speed and blur respectively. 

```matlab
>> load iqa_camera.mat;
>> base_dir = 'C:\nr_data\';
>> [NR_pars_panIPS] = calculate_NRpars(ccriq_dataset, base_dir, 'none', @nrff_panIPS);
>> [NR_pars_blur] = calculate_NRpars(ccriq_dataset, base_dir, 'none', @nrff_blur);
```

Alternatively, unzip the contents of `demo1.zip` and `demo2.zip` into directory `C:\nr_data\`. 
The important thing is to have parameters calculated that strictly adhere to the format specified in [calculate_NRpars.m](CalculateNRpars.md). If the parameters have already been calculated, `calculate_NRpars.m` will load the data and return quickly. 

Function [export_NRpars](export_NRpars.md) exports parameter data into an Excel or CSV file. This is the recommended method for building metrics in MATLAB. 

This call exports the parameter data and MOS scores into an Excel file named "example.xls".
```matlab
>> export_NRpars(ccriq_dataset, [NR_pars_panIPS, NR_pars_blur], [], "excel", "example.xls");
```

Alternatively, this call exports the parameter data and MOS scores into a CSV file "example.csv"
```matlab
>> export_NRpars(ccriq_dataset, [NR_pars_panIPS, NR_pars_blur], [], "csv", "example.csv");
```

You can then use any language of choice to manipulate the data and preform model creation. Popular alternatives are **R**, **Python**, **Stata**, **MS-Excel**, etc. 

## Option 2. Export Data to MATLAB

Function `export_NRpars` also returns MATLAB variables with the same information as the Excel and CSV files created above. These variables provide a simplified interface to the information in `NR_pars_panIPS` and `NR_pars_blur`. This code also handles the issue of separating training data from verification data.  
```matlab
>> [Xtrain, Xtest, ytrain, ytest] = export_NRpars(ccriq_dataset, [NR_pars_panIPS, NR_pars_blur], [], "none", "none");
```
where:
* `Xtrain` contains parameter data for all training media
* `ytrain` contains subjective data for all training media
* `Xtest` contains parameter data for all verification media
* `ytest` contains subjective data for all verification media
Note that these variables lack parameter name labels. Consult the CSV or Excel file for that information (see above).

## Option 3. Evaluate Dataset Differences for Optimal Compromises

Function [compromise_NRpars.m](CompromiseNRpars.md) provides insights into interactions between [subjective datasets](SubjectiveDatasets.md), NR parameter weights, and the overall performance of an NR metric built from those NR parameters. 
Let us build linear metrics using two parameters:
* nrff_blur.m NR parameter 1, "blur"
* nrff_panIPS.m NR parameter 7, "PanSpeed"

[compromise_NRpars.m](CompromiseNRpars.md) scales all MOSs and NR parameter values to [0..1] where 0 is best and 1 is worst.
The common scale helps us understand metric performance. 
Each linear metric coefficient is a fraction that indicates the importance of that NR parameter in the overall metric.

```matlab
>> compromise_NRpars([bid_dataset ccriq_dataset cid2013_dataset cv_dataset its4s2_dataset], base_dir, true, @nrff_blur, 1, true, @nrff_blur, 2, true)
```

NR parameters are specified in triples: pointer to NRFF function, the parameter number (see [analyze_NRpars.m](AnalyzeNRpars.md)), and a Boolean indicating whether is positively correlated to MOS. 

This call to `compromise_NRpars.m` builds a two parameter linear model for five image quality datasets: BID, CCRIQ, CID2013, CCRIQ2+VIME1, and ITS4S2. The two parameters are similar estimates of overall image blur, focusing on the most blurred areas.

Omitting preliminary status reports, the above code writes the following information to the MATLAB command line: 
```
Parameter List:
1  unsharp
2  viqet-sharpness


MOS scaled so 0 = best, 1 = worst

parameter scaling factors (before metric) are as follows:
1 - ((par 1) - 0.000 ) /  4.0000
1 - ((par 2) - 1.000 ) /  7.0000

Parameter to parameter correlations, pooled data
    1     2    
1   1.00  0.88 
2   0.88  1.00 


Parameter to dataset correlations
                       1     2    
                 bid   0.51  0.47 
               ccriq   0.61  0.67 
             cid2013   0.73  0.74 
                 C&V   0.50  0.46 
              its4s2   0.55  0.61 
              pooled   0.50  0.56 


Linear metric weights and performance, when trained separately on each dataset
                 bid    1.72 * par1 + -0.12 * par2 + -0.61  ( 0.51 correlation)
               ccriq    0.24 * par1 +  0.86 * par2 +  0.01  ( 0.67 correlation)
             cid2013    0.74 * par1 +  0.70 * par2 + -0.11  ( 0.75 correlation)
                 C&V    1.23 * par1 +  0.04 * par2 + -0.17  ( 0.50 correlation)
              its4s2   -0.12 * par1 +  0.77 * par2 +  0.19  ( 0.61 correlation)
              pooled    0.09 * par1 +  0.73 * par2 +  0.12  ( 0.56 correlation)

See figure 1 for weighted compromise
```

![Figure 1. Compromise NRpars](/documentation/images/demo3_compromise_NRpars.jpg)

This figure graphs metric performance (Pearson correlation) of different compromises between the two parameters. The weight of par1 decreases (100%, 90%, ..., 10%, 0%) while the weight of par2 increases (0%, 10%, ..., 90%, 100%).
Thus, the plot helps the user understand the relative importance of each parameter for each dataset. 

Function [compromise_NRpars.m](CompromiseNRpars.md) can also be called for three or more NR parameters. In this case, the above graph is omitted. The example call below shows the relative importance of the three NR parameters in version 1 of [metric Sawatch](MetricSawatch.md), for six image quality datasets and four video quality datasets.
The third input argument is `false` because the NR parameters 1, 2, and 3 in `metric_sawatch.m` have already been scaled to [0..1].

```matlab
>> load iqa_camera.mat;
>> compromise_NRpars([bid_dataset ccriq_dataset cid2013_dataset cv_dataset its4s2_dataset ], base_dir, false, @nrff_panIPS, 7, true, @nrff_blur, 2, true, @nrff_auto_enhancement, 1, true)

% Note: status information is omitted from this documentation

Parameter List:
1  PanSpeed
2  viqet-sharpness
3  white level


MOS scaled so 0 = best, 1 = worst

parameters NOT scaled. Assume already on [0..1] scale

Parameter to parameter correlations, pooled data
    1     2     3    
1   1.00 -0.00 -0.00 
2  -0.00  1.00  0.26 
3  -0.00  0.26  1.00 


Parameter to dataset correlations
                       1     2     3    
                 bid  -0.00 -0.47 -0.16 
               ccriq  -0.00 -0.67 -0.33 
             cid2013   0.00 -0.74 -0.48 
                 C&V   0.00 -0.46 -0.32 
              its4s2  -0.00 -0.61 -0.20 
              pooled   0.00 -0.56 -0.31 


Linear metric weights and performance, when trained separately on each dataset
                 bid    0.29 * par1 + -0.11 * par2 + -0.00 * par3 +  0.00  ( 0.49 correlation)
               ccriq    0.30 * par1 + -0.14 * par2 + -0.00 * par3 +  0.00  ( 0.68 correlation)
             cid2013    0.33 * par1 + -0.16 * par2 + -0.00 * par3 +  0.00  ( 0.74 correlation)
                 C&V    0.26 * par1 + -0.08 * par2 + -0.00 * par3 +  0.00  ( 0.49 correlation)
              its4s2    0.24 * par1 + -0.10 * par2 + -0.00 * par3 +  0.00  ( 0.61 correlation)
              pooled    0.28 * par1 + -0.10 * par2 + -0.00 * par3 +  0.00  ( 0.58 correlation)

Skipping weighted compromise; this analysis requires exactly two parameters
```

## Option 4: Implement a NR Metric

This repository offers a research platform. We assume that, once a metric is developed, it will be coded in a different language for distribution to users. However, there is also a need to feed the NR metric into future research. 
The NRFF format is not optimal for this purpose, because the NR features and NR parameters must be re-calculated.

This workflow offers an alternative: a function that computes a specific, known NR metric from NR parameters.
Our goal is a function that is compatible with the no reference feature function (NRFF) specifications used by [analyze_NRpars.m](AnalyzeNRpars.md), [calculate_NRpars.m](CalculateNRpars.md), and [compromise_NRpars.m](CompromiseNRpars.md).

Of the many NRFF function call options, a metric function only needs two:
* 'group'
* 'parameter_names'

Plus a new interface option:
* 'compose'

To demonstrate, we will use the CCRIQ dataset described by `ccriq_dataset` and version 1 of [metric_sawatch.m](MetricSawatch.md). Begin by loading the dataset structures and initializing variables:
```matlab
>> load iqa_camera.mat;
>> image_datasets = [bid_dataset ccriq_dataset cid2013_dataset cv_dataset its4s2_dataset livewild_dataset ];
```

The 'group' option returns a short string that uniquely identifies this group of NR parameters and NR metric.
```matlab
>> metric_sawatch('group', image_datasets, base_dir)
ans =
    'sawatch'
```
The `parameter_names` option returns a cell array with each NR parameter and the NR metric. The three NR parameters are scaled to [0..1] and copied into Sawatch's data file. Thus, their values are available to provide RCA. 
```matlab
>> metric_sawatch('parameter_names', image_datasets, base_dir)
ans =
  1×4 cell array
    {'WhiteLevel'}    {'Blur'}    {'PanSpeed'}    {'Sawatch'}
```

The 'compose' option calculates the NR metric from already calculated NR parameters. This code assumes that each NR parameter was calculated from an NRFF. For version 1 of Sawatch, the three NR parameters are calculated by `nrff_auto_enhancement.m`, `nrff_blur.m`, and `nrff_panIPS.m`.
```matlab
>> base_dir = 'C:\nr_data\';
>> NRpars = metric_sawatch('compose', [bid_dataset ccriq_dataset cid2013_dataset cv_dataset its4s2_dataset], base_dir);
```

Alternatively, NR metrics can be calculated using [calculate_NRpars.m](CalculateNRpars.md).
```
>> NRpars = calculate_NRpars([bid_dataset ccriq_dataset cid2013_dataset cv_dataset its4s2_dataset], base_dir, 'none', @metric_sawatch);
```

The [metric_sawatch.m](MetricSawatch.md) code uses [calculate_NRpars.m](CalculateNRpars.md) to load the features for each dataset in turn.  
The NR parameter and NR metric data are saved by dataset to "C:\nr_data\group_sawatch\" as explained in [Demo #1](Demo1.md). 

Function `metric_sawatch.m` can now be passed into [analyze_NRpars.m](AnalyzeNRpars.md) and [compromise_NRpars.m](CompromiseNRpars.md). For example:
```
>> analyze_NRpars([bid_dataset ccriq_dataset cid2013_dataset cv_dataset its4s2_dataset], base_dir, @metric_sawatch);

% Note: status information is omitted from this documentation

--------------------------------------------------------------
1) WhiteLevel 
bid              corr =  0.16  rmse =  1.00  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.83]
ccriq            corr =  0.33  rmse =  0.96  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.95]
cid2013          corr =  0.48  rmse =  0.79  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.89]
C&V              corr =  0.32  rmse =  0.68  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.91]
its4s2           corr =  0.20  rmse =  0.73  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.90]

average          corr =  0.30  rmse =  0.83
pooled           corr =  0.31  rmse =  0.86  percentiles [ 0.00, 0.00, 0.00, 0.00, 0.95]


--------------------------------------------------------------
2) Blur 
bid              corr =  0.49  rmse =  0.88  percentiles [ 0.30, 0.49, 0.55, 0.63, 0.83]
ccriq            corr =  0.66  rmse =  0.76  percentiles [ 0.23, 0.41, 0.52, 0.61, 0.85]
cid2013          corr =  0.75  rmse =  0.60  percentiles [ 0.22, 0.39, 0.46, 0.53, 1.00]
C&V              corr =  0.49  rmse =  0.63  percentiles [ 0.32, 0.42, 0.46, 0.52, 0.78]
its4s2           corr =  0.60  rmse =  0.60  percentiles [ 0.25, 0.42, 0.48, 0.57, 0.85]

average          corr =  0.60  rmse =  0.69
pooled           corr =  0.55  rmse =  0.75  percentiles [ 0.22, 0.42, 0.50, 0.58, 1.00]


--------------------------------------------------------------
3) PanSpeed 
bid              corr =   NaN  rmse =   Inf  percentiles [ 0.08, 0.08, 0.08, 0.08, 0.08]
ccriq            corr =   NaN  rmse =   Inf  percentiles [ 0.08, 0.08, 0.08, 0.08, 0.08]
cid2013          corr =   NaN  rmse =   Inf  percentiles [ 0.08, 0.08, 0.08, 0.08, 0.08]
C&V              corr =   NaN  rmse =   Inf  percentiles [ 0.08, 0.08, 0.08, 0.08, 0.08]
its4s2           corr =   NaN  rmse =   Inf  percentiles [ 0.08, 0.08, 0.08, 0.08, 0.08]

average          corr =   NaN  rmse =   Inf
pooled           corr =   NaN  rmse =   Inf  percentiles [ 0.08, 0.08, 0.08, 0.08, 0.08]


--------------------------------------------------------------
4) Sawatch 
bid              corr =  0.50  rmse =  0.88  percentiles [ 2.15, 2.79, 2.96, 3.07, 3.43]
ccriq            corr =  0.64  rmse =  0.79  percentiles [ 1.45, 2.81, 3.02, 3.22, 3.55]
cid2013          corr =  0.71  rmse =  0.63  percentiles [ 1.59, 2.99, 3.13, 3.26, 3.57]
C&V              corr =  0.48  rmse =  0.63  percentiles [ 1.63, 3.02, 3.14, 3.20, 3.38]
its4s2           corr =  0.58  rmse =  0.61  percentiles [ 1.61, 2.92, 3.08, 3.20, 3.53]

average          corr =  0.58  rmse =  0.71
pooled           corr =  0.56  rmse =  0.75  percentiles [ 1.45, 2.88, 3.06, 3.20, 3.57]
```
Note that NR parameter **PanSpeed** yields a constant value for images. 
