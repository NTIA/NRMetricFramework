# MATLAB function st_statistic

## Usage

This function can be thought of as a generic utility function that computes statistics. Given a reasonable understanding of statistics, there is no real reason to use this function (it's more or less trivial to use MATLAB's built in functions) but this function is called in many other pieces of code. 

Give the function a particular request flag (Ie. "mean", "std", 'various') and the function will compute the requested statistic over the raw data. The data will either be coerced into a row vector ("ST" or "SpatialTemporal") or it will be split into frame level statistics by 'Spatial'.


## Details

The function internally calls various MATLAB functions to calculate the statistics. These are generally the functions like 'mean', 'std', 'corrcoef' etc.

## Inline Documentation 

```text
ST_STATISTIC
  Compute the requested spatial-temporal (ST) collapsing function.
function [data,names] = st_statistic(request, raw_data, option)
 ST_STATISTIC
  Compute the requested spatial-temporal (ST) collapsing function.
 SYNTAX
  [data, names] = st_statistic(request, raw_data)
  [data, names] = st_statistic(request, raw_data, option)
 DESCRIPTION
  Compute the requested spatial or temporal collapsing function, using
  ALL data in the array or matrix, 'raw_data', and return the
  results in 'data'. Return variable 'names" will have the name of the
  function calculated (typically the same as 'request').

  The available percentile functions are as follows. The meanings are as
  defined in "Video Quality Measurement Techniques" NTIA Technical Report 02-392.
   'mean', 'std', 'rms', 'min', 'max', 'range' 'abs_mean'
   '10%', '25%', '50%', '75%', '90%',
   'above99%', 'above98%', 'above95%', 'above90%', 'above75%',
   'above50%', 'above25%', 'above10%',
           [ The meaning of 'aboveX%' is to average all values above the Xth percentile]
   'above90%tail', 'above95%tail', 'above98%tail', 'above99%tail',
           [ The meaning of 'aboveX%tail' is to average all values above
             the Xth percentile, then subtract the Xth percentile]
   'below1%', 'below2%', 'below5%', 'below10%', 'below25%', 'below50%',
   'below75%' 'below90%'
   'below1%tail, 'below2%tail', 'below5%tail', 'below10%tail', 'below50%tail'
           [ These are as the 'above' but computed below the selected percentile]
   'between25%50%', 'between25%75%', 'between10%90%'
           [ The meanings of 'betweenX%Y%' is to average values between the Xth and Yth percentile ]
   'minkowski(P,R)'
           [ minkowski = mean(abs(raw_data).^P).^(1/R) ]
           Where 'P' and 'R' are replaced with the actual values to be
           used.  For example, 'minkowski(1.8,2.8)' or 'minkowski(6,7)'

  Each of these requests calculates a variety of statistics. 'option' must
  be 'SpatialTemporal'.  The identities and order of the sub-requests will be
  returned in 'names'.
   'various'
       [ 'mean', 'std', 'rms', 'min', 'max', 'range', '10%', '25%', '50%', '75%', '90%', ...
         'between25%50%', 'between25%75%', 'between10%90%' 'above90%' 'below10%' ]
   'varioushigh'
       [ 'mean', 'std', 'max', '75%', '90%', 'above99%', 'above98%', 'above95%', 'above90%', 'above75%' ]
   'variouslow'
       [ 'mean', 'std', 'min', '25%', '10%', 'below1%', 'below2%', 'below5%', 'below10%', 'below25%', 'below50%' ]

 The following values for 'option' input parameters may be specified.

   'SpatialTemporal', or
   'ST',   Apply the requested function simultaneously to all dimensions,
           Spatial and Temporal (ST). Thus, convert all of the data into a
           1D array and apply the collapsing function to that 1D array.
           This is the default behavior.
   'Spatial', Assume that 'raw_data' is formatted as (t,x,y) where 't' is
           time; 'x' and 'y' delineate any spatial indexes. Apply the
           statistic specified in 'request' separately to each value of 't'.

 WARNING: 'nan' and 'inf' values will be discarded.
```
