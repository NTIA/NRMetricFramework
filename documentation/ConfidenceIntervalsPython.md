# MATLAB function `ci_NRpars.m` and `ci_calc.m`

`ci_calc.py` is a python3 implementation of `ci_calc.m`.  Takes a matlab file dataset and matlab no reference parameter(NRPar), and outputs the NRPar with confidence intervals compared to actual user results.  Unfortunately, `ci_calc.py` requires matlab no reference paramater(NRPar) which only be generated using matlab and the NRMetricFramework calculate features function.  However once generated, NRPars be modified using a non-licensed program like octave or python scipy.

## Usage

Let us define ΔM as possible confidence intervals (CI) for an NR metric. That is, for the quality of two stimuli to be considered statistically significant, the NR metric values must differ by at least this CI.

Our goal is to compute the value of ΔM that yields the same error rates as a well-designed subjective test that is conducted in a controlled environment; adheres to ITU-R BT.500, ITU-T Rec. P.913, or ITU-T Rec. P.910; and uses the 5-level absolute category rating (ACR) method. 

* **ideal CI** yields the same error rates as a subjective test with 24 subjects
* **practical CI** yields the same error rates as a subjective test with 15 subjects

**Ideal CI** is a larger CI based on very stringent criteria. **Practical CI** is a smaller CI based on somewhat looser criteria. This increases the likelihood of errors and correct decisions. Both thresholds are justified by lab-to-lab comparisons (e.g., when two labs perform the same subjective test, what is the likelihood that they will reach different conclusions). 

## Details

## Categorizing Conclusions Reached

Let us compare the conclusions reached by a subjective test with the conclusions reached by an NR metric. The possible outcomes are as follows:
 
* Correct ranking = Both conclude that quality of **A** is better than the quality of **B** 
* Correct tie = Both conclude that **A** and **B** have statistically equivalent quality
* False tie = The subjective test can rank order the quality of **A** and **B** but the metric cannot
* False distinction = The metric can rank order the quality of **A** and **B** but the subjective test cannot
* False ranking = The metric and subjective test reach opposing conclusion on the quality ranking of **A** and **B** 

When comparing stimuli MOSs, we use a constant (ΔS = 0.5) threshold based on our analysis of subjective ratings. When comparing NR metric values, we will examine many possible values of ΔM. For each ΔM, we will compare the decisions reached by the subjective test and the decision reached by the metric, for all stimuli pairs in the dataset. The plot displays the likelihood of each outcome, as a function of ΔM. 

Two CI values are computed. **Ideal CI** uses more stringent ΔM selection criteria that limit false ranking to 1% and false distinction to 10%. These are the rates observed when the same subjective test is conducted in two labs, each using 24 subjects. **Practical CI** uses less stringent ΔM selection criteria.  **Practical CI** limits the sum of false ranking and false distinction to 16%. This combined threshold is supported by subjective test data with 15 subjects. However, **practical CI** will yield false ranking incident rates than can be observed in subjective tests. For each CI, the likelihood of all five categories will be printed to the command window.

**Ideal CI** and **practical CI** do not assess the accuracy of a metric. 

## Multiple Datasets
When given multiple subjective datasets, **ci_NRpars.m** will only compare stimuli pairs within each dataset individually. All decisions will be pooled, and all dataset will be weighted equally. 


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

