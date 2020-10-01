# MATLAB function `peek_NRpars.m`
 
## Usage

Visualize the media that are detected by a particular range of NR parameter values. 

## Semantics

Given specific NR parameter and range of parameter values, this function finds the media that have NR parameter values within that range. These images (or the first frame of videos) are displayed, first as thumbnails then full resolution. The list of media is printed to the command line.

## Inline Documentation
```text
PEEK_NRPARS
  View media that trigger a certain range of parameter values
SYNTAX
  peek_NRpars( nr_dataset, base_dir, feature_function, parnum, min_value, max_value)
SEMANTICS
  Intended for debugging NR parameters that provide root cause analysis.
  Images or videos with a specific impairment should produce high or low
  values. This function lets the user specify the range of parameter
  values where the impairment should be detected. The media in that range
  are displayed, first as thumbnails in a 3x4 matrix, then as full
  resolution images. For videos, the first frame is displayed. Additional
  information is printed to the command line. 

 Input Parameters:
  nr_dataset          Data struction. Each describes an entire dataset (name, file location, ...)
  base_dir            Path to directory where NR features and NR parameters are stored.
  feature_function    Pointer to a no-reference feature functions (NRFF) that must 
                      adhere to the interface specified in calculate_NRpars.
  parnum              Parameter number, within @feature_function.
  min_value           Minimum paramter value to select.
  max_value           Maximum parameter value to select.
```
