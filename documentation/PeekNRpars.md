# MATLAB function `peek_NRpars.m`
 
## Usage

Visualize media detected by a particular range of NR parameter values. 

## Semantics

Given specific NR parameters and a corresponding range of values, this function finds the media within the NR parameter value range specified. Found images (or the first frame of videos) are displayed as thumbnails, 12 per figure. Then, each found image is displayed in full resolution, in its own figure. The list of media is printed to the command line.

## Inline Documentation
```text
PEEK_NRPARS
  Visualize media detected by a particular range of NR parameter values.
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
  nr_dataset          Data structure. Each describes an entire dataset (name, file location, ...)
  base_dir            Path to directory where NR features and NR parameters are stored.
  feature_function    Pointer to a no-reference feature functions (NRFF) that must 
                      adhere to the interface specified in calculate_NRpars.
  parnum              Parameter number, within @feature_function.
  min_value           Minimum parameter value to select.
  max_value           Maximum parameter value to select.
```
