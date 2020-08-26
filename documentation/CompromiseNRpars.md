# MATLAB Function `compromise_NRpars.m`

## Usage

`compromise_NRpars` is an auxiliary function that assists in running analysis on a pair of parameters. The function takes a pair of parameters and attempts to find the optimal linear combination of constants `a,b` such that `(a + b = 1)` and the linear combination `a * param1 + b * param2`  maximizes the correlation of the linear combination of paired variables with the response data.

## Details

### Information Displayed

- Correlation between predictor variables
- Correlation between datasets and the linear model of all predictors
- Graph that shows how Pearson correlation changes as parameter weight `a` decreases and parameter weight `b` increases.

### Semantics

The function increments the coefficients in increments of 0.1. Namely a = [0, 0.1, 0.2 ... 1] and b = [1, 0.9, 0.8, ... 0]. The function then tests all the pairs of coefficients with the criteria (a + b = 1) and plots the results. The user can then visually determine the best combination.

## Inline Documentation
```text
 COMPROMISE_NRPARS
    Visualize differences among parameter weights for multiple datasets, to
    help find compromise weights for a linear model.
 SYNTAX
    compromize_NRpars (nr_dataset, base_dir, do_scaling, ...
        feature_function1, parameter1, ispos1, ...
        feature_function2, parameter2, ispos2, ...
        feature_functionN, parameterN, isposN); 
 SEMANTICS
    "nr_dataset" = Data structure
    "base_dir" = Path to directory where NR features and NR parameters are stored.
    "do_scaling" = boolean. usually true, select false if parameters are
    already on a [0..1] scale. 

    The remaqining input parameters are specified in triples, as follows:
    "feature_function" = Function call to compute the feature. This no-reference 
        feature function (NRFF) must adhere to the interface specified in 
        calculate_features.m.
    "parameter1" = Number (offset) of the parameter to be examined.
    "ispos" = true if the parameter is positively correlated to MOS,
        meaning larger values indicate higher quality. "ispos" is false if 
        the parameter is negatively correlated with MOS (i.e., lower values 
        indicate higher quality).
    All parameters will be scaled to [0..1] where 0=best, 1=worst
    MOS are likewise scaled to [0..1] where 0=best, 1=worst

    The goal is a linear model that can be expressed as 
        yhat = 0 + w1*x1 + w2*x2 - ... +wN*xN
    So that it can be easily converted into a linear model expressed as
        yhat = 5 - w1'*x1 - w2'*x2 - ... -wN'*xN

    Restriction: MOSs in all datasets must be scaled to [5..1] where
    5=excellent and 1=bad
```
