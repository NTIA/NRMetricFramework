# MATLAB function `update_NRpars.m`

## Usage
Update saved NR parameter values (calculated by an NRFF function).  

## Details
This function helps the metric developer perform one of two tasks. 
First, this function must be called to update saved NR parameter values (i.e., NRpars.mat files) when this repository is updated to release 3. See the changes listed [here](Updates.md).
Second, this function can be used to remove the NR parameter files, after an NRFF function's parameter code is updated. The feature files will not be erased. 
NR parameter files can also be erased manually.    

## Inline Documentation
```text
function update_NRpars(base_dir, feature_function, action)
   This convenience function updates or erases parameter files. 
 SYNTAX
    update_NRpars(base_dir, feature_function, action)
 SEMANTICS
   This convenience function helps the user update or erase parameter
   files. 

 Input Parameters:
   base_dir = Path to directory where NR features and NR parameters are stored.

   feature_function = Function call to compute the feature. 
       This no-reference feature function (NRFF) must adhere to the
       interface specified in calculate_NRpars.m.

   action = string specifying the requested action:
       'update_pars' = the 'pars' portion of 'feature_function' was
                       updated. All NRpars.mat files will be removed and
                       recalculated. Feature files will not be touched, so
                       recalculating should be relatively fast.
                       Note: the NRpars.mat files will be moved
                       to sub-folder, 'previous_NRpars'.
       'version' = the version of the NRMetricFramework library was
                       updated. All NRpars.mat files must be updated.
```