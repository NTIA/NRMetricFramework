# MATLAB function `analyze_lab2lab.m`
 
## Usage

Compare the conclusions reached by two subjective tests.  

## Semantics

This function implements the techniques described in the following report:

Margaret H. Pinson, "Confidence Intervals for Subjective Tests and Objective Metrics That Assess Image, Video, Speech, or Audiovisual Quality," NTIA Technical Report TR-21-550, October 2020. 
https://www.its.bldrdoc.gov/publications/details.aspx?pub=3253

The function requires raw subjective scores from each test, where the same pool of subjects rated all sequences. If the test contains multiple subject pools, then __analyze_lab2lab__ must be called separately for each subject pool. Based on prior subjective testing, well-designed and carefully conducted subjective tests should have a _disagree_ rate < 1%. If _disagree_ rate > 1%, there are probably genuine differences between the labs that impact the rank ordering of stimuli (e.g., how subjects were trained, rating method, monitor used). 

## Inline Documentation
```text
% ANALYZE_LAB2LAB
%   Analyze the conclusions reached by two subjective test labs.
% SYNTAX
%   [agree_ranking, agree_tie, unconfirmed, disagree] = ...
%       analyze_lab2lab( lab1, lab2)
% SEMANTICS
%   Analyze the conclusions reached by two subjective test labs (lab1 and 
%   lab2). Comparisons are made using the Student's t-test. 
%
% Input:
%   lab1 and lab2 contain the same list of media (one per row) and subjects
%   (one per column). An occasional missing score is okay, replaced with NaN.
%   However, an identical set of subjects must rate all stimuli. Deviations
%   from this restriction will yield invalid (random) results.
%
% Output: given stimulus pairs (A, B) 
%   agree_ranking = likelihood that both labs conclude that A has
%       significantly better quality than B (or vice versa).
%   agree_tie = likelihood that both labs conclude A and B have
%       statistically equivalent quality
%   unconfirmed = likelihood that one lab concludes the stimuli are
%       statistically equivalent, but the other lab concludes that
%       A has significantly better quality than B
%   disagree = likelihood that lab1 concludes that A is significantly
%       better than B, but lab2 concludes that A is significantly worse
%       than B (or vice versa)
```
