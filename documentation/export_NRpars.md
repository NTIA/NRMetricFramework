# MATLAB function `export_NRpars.m`

## Usage

Function `export_NRpars` writes NR parameter values, MOSs, and (optionally) interim featuress to an XLS spreadsheet 
for debugging, porting software to another language, or manipulating these values with other tools. 
The NR parameter values are also returned as local variables. 

## Details
Normally, this information is saved in the [dataset variables](DatasetStructure.md) and the [parameter files](Demo1.md) and [intermediate feature files](Demo1.md).
Function `export_NRpars` pulls the information from these locations and re-formats it.
By default, `export_NRpars` only returns the 90% of media marked for use during metric training.

The optional input argument `verify` can be used to obtain the 10% of media that are held in reserve to verify the performance of NR parameters.
__For those performance reports to be valid, the `verify` values must never be used to train any NR parameter or NR metric.__
This prohibition includes testing cycles during machine learning. 

See [import_dataset](ImportDataset.md) and [Demo1](Demo1.md) for more details.

## Inline Documentation

```text
% EXPORT_NRPARS
%   Write NR parameter values, MOSs, and (optionally) interim features to
%   a spreadsheet for debugging, porting software to another language, or
%   manipulating NR parameters and NR features with other tools. 
%
% SYNTAX
% [Mdata] = export_NRpars(nr_dataset, data_dir, feature_function, path);
%   export_NRpars(...,'option');       % append options to above function call
%
% SEMANTICS
%  The dataset structures and NR parameter structures are complex.
%  This function exports just the data needed to train or verify a parameter
%  or metric. Data returned in variables and saved to an XLS file. 
%
% Input Parameters:
%   nr_dataset          Data structure. Must contain only one dataset.
%   data_dir            Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature function (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%                       Must contain only one function. 
%   pname               Path (directory) where the XLS file will be written. 
%                       Set to [] to only return per-media data as 
%                       output parameters. Full path to file recomended
%
%   Optional parameters. Some options contradict others.
%
%   'train'             Default. Return the training data only. 
%   'verify'            Return verification data. WARNING: this data
%                       must be held in reserve until final verification of
%                       a metric immediately prior to publication. The
%                       verification data must not be used for machine
%                       learning training/testing cycles.
%   'media', [m1, m2, ... mN] Export raw feature data for the numbered
%                       media. By default, export features for media 1 to 10. 
%   'nofeatures'        Do not write features; only write NR parameters.
%                       Use this option if no features are available, or if
%                       exporting metric_sawatch.m, or if features were deleted. 
%
% Output Parameters:
%
%  Mdata                Table that holds MOSs and NR parameters, as per
%                       file "data_group".
%
% Output Files:
%   Create one files in directory pname, named after the dataset and parameter
%   group (dataset_group.xls). This spreadsheet has the following sheets:
%
%   Sheet 'NRpars' contains columns for the media file names, MOS, RAW_MOS,  
%   and each NR parameter in feature_function.
% 
%   For each media selected, one sheet for each feature. Media and features
%   are numbered (e.g., M1, M2, ... and F1, F2, ...), and the sheets named
%   with these two abbreviations (e.g., M1_F1, M1_F2, M2_F1). Constraints
%   on XLS sheet names prevents more explanatory sheet names.
%
%   Each feature sheet contains one row for each frame in a video, or one
%   row for images. The columns contain feature values. If the feature
%   contains a vector of values, the column names append the vector offset, 
%   such as (1), (2), ...
%
% Example Function Calls:
%   
%   export_NRpars(ccriq_dataset, 'C:\features', @nrff_blur, 'c:\temp\', 'nofeatures')
%   export_NRpars(ccriq_dataset, 'C:\features', @metric_sawatch, 'c:\temp\', 'nofeatures')
```
