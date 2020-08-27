# MATLAB function `ci_NRpars.m` and `ci_calc.m`

Note that:
* `ci_calc.m` has a standalone interface
* `ci_NRpars.m` interfaces with the rest of the NRMetricFramework, and calls `ci_calc.m` to perform calculations

## Reference

[1] Margaret Pinson, "Confidence Intervals for Subjective Tests and Objective Metrics That Assess Image, Video, Speech, or Audiovisual Quality," NTIA Technical Report, Publication Pending.

## Usage

This function implements the techniques described in [1]. The goal is to measure the precision of objective metrics that assess image quality, video quality, speech quality, or the overall audiovisual quality. This method was developed using data from 60 subjective tests and uses a confusion matrix to classify the conclusions reached when two subjective test labs perform the same experiment. This allows us to compute the metric’s confidence interval (CI) and, when CIs are used to make decisions, to prove whether the metric performs similarly to a subjective test with 15 or 24 subjects. When confidence intervals are not used, the metric’s precision is likened to a certain number of people in an ad-hoc quality assessment.  

Functions `ci_NRpars.m` calls `ci_calc.m` calculate the following values:

* **Ideal CI**, calculated with strict criteria 
* Whether the metric is equivalent to a 24 person subjective test, when using **ideal CI** 
* **Practical CI**, calculated with less stringent criteria  
* Whether the metric is equivalent to a 15 person subjective test, when using **practical CI** 
* **N**, the number of subjects in an ad-hoc assessment or pilot test that is equivalent to the metric

We recommend **practical CI** for most uses. Both thresholds are justified by lab-to-lab comparisons (e.g., when two labs perform the same subjective test, what is the likelihood that they will reach different conclusions).  

When using **ideal CI** or **practical CI**, metric values indicate a preference only when the difference is greater than the CI.  

# Details

## Assumptions

* The subjective test must be conducted using the Absolute Category Rating (ACR) scale with five levels. The mean opinion scores (MOS) must remain on the [1..5] scale and must be calculated as a simple average of subject ratings. Normalization, scaling, and fitting are not allowed, as this would change characteristics of rating distributions.

* The MOSs must be from a well-designed and carefully conducted subjective test that adheres to an international standard, such as ITU-R Rec. BT.500, ITU-T Rec. P.913, or ITU-T P.800. 

* This statistical method assesses metric precision. **Ideal CI** and **practical CI** do not assess the accuracy of a metric. 

* **N** is limited to 0, 1, 2, 3, 6, 9, or 12 subjects. Fractions are not allowed.

## Categorizing Conclusions Reached

A confusion matrix is used to compare the conclusions reached by the metric and the subjective test. This confusion matrix contains the following categories:

* Correct ranking = Both conclude that quality of **A** is better than the quality of **B** 
* Correct tie = Both conclude that **A** and **B** have statistically equivalent quality
* False tie = The subjective test can rank order the quality of **A** and **B** but the metric cannot
* False distinction = The metric can rank order the quality of **A** and **B** but the subjective test cannot
* False ranking = The metric and subjective test reach opposing conclusion on the quality ranking of **A** and **B** 

Conclusions about the metric are printed to the MATLAB command window. In addition, the incidence rates are plotted as a function of CI. This allows the user to choose a CI value other than those recommended.
 
## Multiple Datasets
When given multiple subjective datasets, **ci_NRpars.m** will only compare stimuli pairs within each dataset individually. All decisions will be pooled, and all dataset will be weighted equally. 


## Inline Documentation
```text
SYNTAX
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

