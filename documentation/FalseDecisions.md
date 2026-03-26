# MATLAB function `false_decisions.m`

Calculate the likelihood that a metric will falsely rank media, when compared to subjective ratings (truth data).

## Usage

Calculate the likelihood that a metric will falsely rank media. Requires (1) a metric that detects the quality of videos and (2) a dataset of videos with 5-level ACR ratings in the range of [1..5].

Function `false_decisions.m` is a variant of the false ranking statistic described in [[7]](Publications.md). 
When the false ranking rate is less than 13\%, the metric performs equivalently to or better than one person. See [[7]](Publications.md) for details. 

## Details

## Categorizing Conclusions Reached

The numerator is the incidence rate where the metric will say (A) is better than (B) when a subjective test would say that the quality of (A) is significantly worse than the quality of (B). 
For this significance test, we use a constant confidence interval of (ΔS = 0.5) based on our analysis of subjective ratings in [[7]](Publications.md). 

The denominator is the incidence rate where the metric says that (A) and (B) have different quality. Metric ties are ignored. 

Incidents where the metric concludes that (A) and (B) have the same quality are omitted from this calculation. 
RCA metrics and inaccurate NR metrics often produce identical values. Including their data in the denominator would skew the statistic. 

If given mean opinion scores (MOS), `false_decisions.m` will use the expected confidence interval for a well conducted subjective test from [[7]](Publications.md), which is 0.5. If given individual subject ratings, `false_decisions.m` will instead calculate, apply, and report the confidence interval of this dataset. 

```text
false_decisions
  Estimate the false decision rate of a video quality metric.
SYNTAX
  [rate threshold_level] = false_decisions(mos, metric)
  [rate threshold_level] = false_decisions(ratings, metric)
SEMANTICS
  This function calculates the false decision rate of a metric, when
  compared to a subjective test. Note that metric decisions are
  deterministic (better, worse, or identical) while the subjective
  test's decisions use confidence intervals to reach statistically
  significant conclusions. The false decision rate is computed  
  as follows:

  The numerator is the incidence rate where the metric will say
  (A) is better than (B) when a subjective test would say that the
  quality of (A) is significantly worse than the quality of (B). 

  The denominator is the incidence rate where the metric says that (A)
  and (B) have different quality. Metric ties are ignored. 

  Incidents where the metric concludes that (A) and (B) have the same quality
  are ignored.

  If the 1st input parameter is a vector of mean opinion scores
  (MOS), a default MOS confidence interval of 0.5 will be used. If the 1st 
  input parameter is a matrix of subject ratings (video, subject), then the
  confidence interval of the dataset will be computed and used.

Input Parameters:
  mos     For one dataset, a double array that contains the mean opinion
          score (MOS) for each stimulus in the dataset ... OR ...
  ratings For one dataset, a matrix (stimuli, subjects) that contains
          individual subject ratings for each stimulus in the dataset.
  metric  For one dataset, a double array that contains one metric's
          value for each stimulus in the dataset. Order of stimuli must be
          identical to input variable MOS.

Output Parameters:
  rate       False decision rate (expressed as a fraction)
  threshold_level  Confidence interval threshold (calculated or default)

  The theoretical underpinnings of this algorithm are published in
  Margaret H. Pinson, "Confidence Intervals for Subjective Tests and
  Objective Metrics That Assess Image, Video, Speech, or Audiovisual
  Quality," NTIA Technical Report TR-21-550, October 2020.
  https://www.its.bldrdoc.gov/publications/details.aspx?pub=3253
```

