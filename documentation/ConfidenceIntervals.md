# MATLAB function `ci_NRpars.m` and `ci_calc.m`

Note that `ci_NRpars.m` calls `ci_calc.m` to perform calculations. `ci_calc.m` provides a standalone interface.

## Reference

[1] Margaret Pinson, "Confidence Intervals for Subjective Tests and Objective Metrics That Assess Image, Video, Speech, or Audiovisual Quality," NTIA Technical Report, Publication Pending.

## Usage

This function implements the techniques described in [1]. The goal is to measure the precision of objective metrics that assess image quality, video quality, speech quality, or the overall audiovisual quality. This method was developed using data from 60 subjective tests and use a confusion matrix classify the conclusions reached when two subjective test labs perform the same experiment. This allows us to compute the metric’s confidence interval (CI) and, when CIs are used to make decisions, to prove whether the metric performs similarly to a subjective test with 15 or 24 subjects. When confidence intervals are not used, the metric’s precision is likened to a certain number of people in an ad-hoc quality assessment.  

Functions `ci_NRpars.m` calls `ci_calc.m` calculate the following values:

* **Ideal CI**, calculated with strict criteria 
* Whether the metric is equivalent to a 24 person subjective test, when using **ideal CI** 
* **Practical CI**, calculated with less stringent criteria  
* Whether the metric is equivalent to a 15 person subjective test, when using **practical CI** 
* **N**, the number of subjects in an ad-hoc assessment or pilot test that is equivalent to the metric

**Ideal CI** is a larger CI based on very stringent criteria. **Practical CI** is a smaller CI based on somewhat looser criteria. This increases the likelihood of errors and correct decisions. Both thresholds are justified by lab-to-lab comparisons (e.g., when two labs perform the same subjective test, what is the likelihood that they will reach different conclusions). We recommend practical CI for most uses. 

When using **ideal CI** or **practical CI**, metric values indicate a preference only when the difference is greater than the CI.  

# Details

## Categorizing Conclusions Reached

Functions `ci_NRpars.m` calls `ci_calc.m` print the conclusions reached to the MATLAB command window. 

In addition, a plot is created that shows how the incidence rates change as a function of CI. This allows the user to choose a CI value other than those recommended. On these plots, dashed vertical lines show the locations for **ideal CI** and **practical CI**. These plots show the following categories from the confusion matrix. These lines let us compare the conclusions reached by a subjective test with the conclusions reached by an NR metric. The possible outcomes are as follows:
 
* Correct ranking = Both conclude that quality of **A** is better than the quality of **B** 
* Correct tie = Both conclude that **A** and **B** have statistically equivalent quality
* False tie = The subjective test can rank order the quality of **A** and **B** but the metric cannot
* False distinction = The metric can rank order the quality of **A** and **B** but the subjective test cannot
* False ranking = The metric and subjective test reach opposing conclusion on the quality ranking of **A** and **B** 

When comparing stimuli MOSs, we use a constant (ΔS = 0.5) threshold to detect statistical differences between MOSs, based on our analysis of subjective ratings. When comparing NR metric values, we will examine many possible values of ΔM. For each ΔM, we will compare the decisions reached by the subjective test and the decision reached by the metric, for all stimuli pairs in the dataset. 

Note that **Ideal CI** and **practical CI** do not assess the accuracy of a metric. 

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

