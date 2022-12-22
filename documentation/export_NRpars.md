# MATLAB function `export_NRpars.m`

## Usage

Function `export_NRpars` writes a spreadsheet that contains the media names, MOSs, and parameter values for one dataset.
These values are also returned as local variables. 

## Details
Normally, this information is saved in the [dataset variables](DatasetStructure.md) and the [parameter files](Demo1.md).
Function `export_NRpars` pulls the information from these locations and re-formats it.
By default, `export_NRpars` only returns the 90% of media marked for use during metric training.

The optional input argument `verify` can be used to obtain the 10% of media that are held in reserve to verify the performance of NR parameters.
__For those performance reports to be valid, the `verify` values must never be used to train any NR parameter or NR metric.__
This prohibition includes testing cycles during machine learning. 

See [import_dataset](ImportDataset.md) and [Demo1](Demo1.md) for more details.

## Inline Documentation

```text
EXPORT_NRPARS
  Write NR parameters or NR metrics and MOSs to a spreadsheet or matrix
SYNTAX
  [values, mos, par_name, media_name] = export_NRpars(dataset, feature_function, base_dir, fname);
  export_NRpars(...,'clip',value);
SEMANTICS
 The dataset structures and NR parameter structures are complex.
 This function exports just the data needed to train or verify a parameter
 or metric. Data returned in variables and saved to an XLS file. 

Input Parameters:
  nr_dataset          Data structure. Each describes an entire dataset (name, file location, etc.)
  base_dir            Path to directory where NR features and NR parameters are stored.
  feature_function    Pointer to a no-reference feature function (NRFF) that must 
                      adhere to the interface specified in calculate_NRpars.
  fname               The Excel filename used to save the data. 
                      Set to [] to only return data as output parameters. 

  Optional parameters. Some options contradict others.

  'train',            Default. Return the training data only. 
  'verify'            Return verification data. WARNING: this data
                      must be held in reserve until final verification of
                      a metric immediately prior to publication. The
                      verification data must not be used for machine
                      learning training/testing cycles. 

Output Parameters:

 values           The feature matrix (par_name, file_list)
 mos              The MOS vector (file_list)
 par_name         Names of parameters
 file_list        Names of files
```
