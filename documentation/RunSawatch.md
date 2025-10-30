# MATLAB function `run_sawatch.m`

## Usage
Function run_sawatch.m runs the NR metric Sawatch on a list of files. 

It was created in support of the ITU-T Study Group 12 validation of NR metrics 
in 2025/2026, J.noref. 

## Semantics
Function run_sawatch.m takes as input a list of files, and writes the Sawatch
metric values and RCA parameters to an output file. Intermediate files are
written to a data directory and can be deleted after this function finishes.
The data directory allows the run to be interrupted and re-started with minimal
loss of computing time. 

Function run_sawatch.m uses the research code, and does not improve computation speed.

By default, run_sawatch.m assumes a full HD monitor. 

## Inline Documentation
```text
% RUN_SAWATCH
%    Run the NR metric Sawatch on a list of files. Write metric values to a file.
% SYNTAX
%    [nr_dataset] = run_sawatch(input_file, output_file, data_dir)
%    [nr_dataset] = run_sawatch(input_file, output_file, data_dir, parallel_mode, dataset_name, display_rows, display_cols)
% SEMANTICS
%    Read the list of files in `input_file`, one file per line. Can include path names. 
%    Write to `output_file`, one file per line, the file name (no path), Sawatch metric value, and parameter 
%    values. 
%    `data_dir` will be used to hold intermediate files. 
%
%    Optional input parameters (dataset_name, display_rows, display_cols) used to initiate returned variable 
%    `nr_dataset'. By default, dataset_name = `dataset`, display_rows = 1080, display_cols = 1920, and parallel
%    mode = 'none'.
%
%   parallel_model = 
%       'none'      Linear calculation. Parallel processing toolbox avoided.
%       'stimuli'   Parallel processing on the stimuli level. 
%       'tslice'    Divide each stimuli into segments for parallel processing  
%                   Note: tslice mode automatically disabled for images 
%                   (presented as 1 fps sequences), due to inefficiencies. 
%       'all'       Do parallel processing on both the stimuli and tslice level. 
%
%                   (Note: 'all' and 'stimuli' mode cannot save progress
%                   calculating NRpars. Only features can be saved against computer crash.)
```
