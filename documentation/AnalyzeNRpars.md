# MATLAB function `analyze_NRpars.m`

## Usage
Analyze NR parameters (calculated by an NRFF function) against one or more dataset.

## Details
This function helps the metric developer understand the performance of the NR parameter(s) calculated by one NRFF. It provides several different ways to analyze performance, including Pearson correlation, root mean squared error (RMSE), scatter plots. When called with multiple datasets (i.e., a vector containing two or more [dataset structures](DatasetStructure.md)), these analyses show comparative performance from one dataset to another. 


## Inline Documentation
```text
SYNTAX
  analyze_NRpars(nr_dataset, base_dir, feature_function);
  analyze_NRpars(...,'optional_parameter',value);

SEMANTICS
  Analyze the metrics associated with one NR parameter group. 
  This analysis intentionally omits verification stimuli.

Input Parameters:
  nr_dataset         [Dataset structure](DatasetStructure.md) or vector containing 2+ [dataset structures](DatasetStructure.md)
  base_dir           Path to directory where NR features and NR parameters are stored. See [calculate_NRfeatures.m](CalculateFeatures.md)
  feature_function   Pointer to a no-reference feature functions (NRFF) that must adhere to the interface specified in calculate_features.

Optional parameters, appended to the end of the function call. Some options contradict others.

    'clip',         Lower, upper, = clip the parameter values to lie between [lower..upper]  
    'sqrt'          Square root parameter values before analysis
    'square'        Square parameter values before analysis
    'allcategory' N, Merge all datasets together, then split by category. Limited to category 1, 3, or 4. 
    'category', N,  Split each parameter & dataset by category number N. Categories definitions are unique for each dataset. 
                    Category 2 cannot be selected, this analysis is inherently part of the training process. 
                    nr_dataset` must contain only one dataset.

    'info',         List category options for the dataset but don't analyze.
    'outlier',      List the worst outliers
    'par', N,      Only analyze the Nth parameter (identified by number)
    'plot'          Create scatter plots
```
