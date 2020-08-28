# Python application `ci_calc.py`

`ci_calc.py` is a command line python3 implementation of `ci_calc.m`.  Takes a matlab file dataset and matlab no reference parameter(NRPar), and outputs the NRPar with confidence intervals compared to actual user data.

Unfortunately, `ci_calc.py` requires matlab no reference paramater(NRPar) which only be generated using matlab.  Specifically, the NRMetricFramework calculate features function.  However once generated, NRPars be modified using a non-licensed program like octave or python scipy.

## Process and Usage

Please See [ci_NRpars.m and ci_calc.m](ConfidenceIntervals.md).


## Single Datasets Only
`ci_calc.py` can process only one dataset and one no reference parameter(NRPar) at a time.


## Inline Documentation
```text
SYNTAX
  python3 ci_calc.py [options]

  Options:
    -m    <mosFileName> <mosFieldName> <nrParsFileName> <nrParsFieldName>
    -s    <graphSaveFileName>
    -b    Verbose / Program Status

  Misc Options:
    -h --help       Help
    -v --version    Version Number
    -b --verbose    Verbose Messages

  Example:

  ci_NRpars(nr_dataset, base_dir, feature_function, parnum);
SEMANTICS
  Estimate the confidence interval (CI) of an NR metric or parameter, 
  by comparing the conclusions reached by the model with conclusions 
  reached by a subjective test. Both will use a constant confidence 
  interval (CI) to make decisions. The subjective CI is based on
  5-level ACR MOSs. Two recommended CIs are printed to the command window.
  (1) ideal CI, and (2) practical CI. The classification types are plotted, 
  which allows the user to choose an alternate CI.

Input Parameters:
  nr_dataset          Data structures, of datasets to be analyzed. If 2+
                      datasets are provided, then the datasets will be
                      weighted equally.
  base_dir            Path to directory where NR features and NR parameters are stored.
  feature_function    Pointer to a no-reference feature functions (NRFF) that must 
                      adhere to the interface specified in calculate_NRpars.
```

```text
SYNTAX
  [ideal_ci, practical_ci] = ci_calc(metric_name, num_datasets, dataset_names, ...
      dataset_mos, dataset_metrics);
SEMANTICS
    (See ci_NRpars.m above)

Input Parameters:
  metric_name     Character string that contains the metric's name
  num_datasets    Number of subjective datasets
  dataset_names   Cell array. For each dataset (1..num_datasets), a
                  character array that contains the name of this dataset.
  dataset_mos     Cell array. For each dataset (1..num_datasets), a
                  double array that contains the mean opinion score (MOS)
                  for each stimuli in the dataset.
  dataset_metrics Cell array. For each dataset (1..num_datasets), a
                  double array that contains the metric's value for each
                  stimuli in the dataset. Order of stimuli must be
                  identical to dataset_mos.
Constraints:
  All datasets are weighted equally.
  The MOSs must range from 1 to 5. 
```

