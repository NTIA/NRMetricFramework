# MATLAB function `false_decisions.m`

Function `false_decisions.m` a variant of the false ranking statistic described in [[7]](Publications.md). 

## Usage

Calculate the likelihood that an NR metric will falsely rank media, given that the NR metric detects a quality difference between two media.

Requires 5-level ACR ratings in the range of [1..5].

## Details

## Categorizing Conclusions Reached

The numerator is the incidence rate where the metric will say (A) is better than (B) when a subjective test would say that the quality of (A) is significantly worse than the quality of (B). 
For this significance test, we use a constant confidence interval of (ΔS = 0.5) based on our analysis of subjective ratings in [[7]](Publications.md). 

The denominator is the incidence rate where the metric says that (A) and (B) have different quality. Metric ties are ignored. 

Incidents where the metric concludes that (A) and (B) have the same quality are omitted from this calculation. 
RCA metrics and inacurate NR metrics often produce identical values. Including their data in the denominator would skew the statistic. 


```text
false_decisions
  Estimate the false decision rate an NR parameter
SYNTAX
  [rate] = false_decisions(mos, metric)
SEMANTICS

Input Parameters:
  mos     For one dataset, a double array that contains the mean opinion
          score (MOS)for each stimuli in the dataset.
  metric  For one dataset, a double array that contains one metric's
          value for each stimuli in the dataset. Order of stimuli must be
          identical to input variable mos.

Output Parameters
  rate =  The false ranking rate, expressed as a fraction. 
          Metric ties are omitted from this calculation
```

