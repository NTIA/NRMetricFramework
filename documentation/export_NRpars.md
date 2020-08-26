# MATLAB function `export_NRpars.m`

## Usage

`export_NRpars` is intended to accommodate different user preferences for model building and to leverage MATLAB's full statistical modeling libraries. `export_NRpars` converts a given data set and multiple parameter structures calculated from that dataset into four matrices. These matrices can then be used by any other MATLAB libraries or can be exported using the optional string arguments to either Excel or CSV formats respectively. This is intended
to facilitate model development in other frameworks and programming languages.


## Details

`export_NRpars` works generally by iteratively building a matrix from each NR_pars by pulling
out the data for each parameter and appending the data as a column in the matrix. The MOS scores are pulled 
directly from the dataset structure and returned as a vector. 

`export_NRpars` will also read from the dataset structure whether the corresponding row is training or verification
data. Verification and testing are used interchangeably in the documentation. The resulting X and y matrices are then split and returned as `Xtrain, Xtest, ytrain, ytest` respectively. This is done to facilitate proper procedures for training and testing models. 

The user is expected to use the training matrices to train the model and the testing matrices to verify the model.

We note that the only mechanism the function uses to ensure ordering of the MOS scores and the features in the matrices is the order they are presented in the parameter structures and the dataset structures. Therefore, the user should take care to ensure these two fields are properly aligned. Additionally the function maintains a hashmap to maintain ordering between MOS and features by hashing on the file name.

See [import_dataset](ImportDataset.md) and [Demo1](Demo1.md) for more details on importing data sets and MOS scores.

## Inline Documentation

```text
 EXPORT_NRPARS

   Write NR parameters or NR metrics and MOSs to a spreadsheet or matrix

 SYNTAX

 [Xtrain, Xverify, ytrain, yverify] = export_NRpars(dataset, param_structs,
           param_list, format, fname);
 
 SEMANTICS

  The dataset structures and NR parameter structures are complex.
   
  This function exports just the data needed to train or test a parameter
  or metric. Data are formatted into matrixes and exported.
  Four matrices are returned (Xtrain, Xtest, ytrain, and ytest) to
  facilitate proper separation of training and verification data.

 Arguments

   dataset: The dataset from which all param_structs are computed from.
   The current program currently only works with one dataset. 

   param_structs: one or more parameter structures (a vector).

   param_list: The array of strings which correspond to the desired
   parameters within the param_structs array. Input as an empty array ([])
   if all parameters in all structs are desired.

   format: The format the user would like to export the matrices as.
   Options are "csv" and "excel" for csv and excel files respectively. The
   user can also input "none" if no exporting is neccesary

   fname: The filename the user would like to export the matrices as. If
   the option "none" is inputted, this parameter does not matter. If "csv"
   is chosen, then the prefixes "test_" and "train_" will be prepended. 

Output

  Xtrain: The feature matrix for training
  Xverify: The feature matrix for verification
  ytrain: The MOS vector for training
  ytest: The MOS vector for verification
   
 Examples:

 return all parameters from NR_pars1 as MATLAB variables
 [Xtrain, Xverify, ytrain, yverify] = export_NRpars(Example_Dataset, NR_pars1, ...
      [], "none", "none")

  save five parametes from three different parameter structs to a CSV file
  and return the same data to MATLAB variables.
 [Xtrain, Xverify, ytrain, yverify] = export_NRpars(Example_Dataset, ...
       [NR_pars1, NR_pars2, NR_pars3], [Parm1, Param2, Param3, Param4, Param5], "csv", "test.csv")

 save one parameter to an Excel spreadsheet
 export_NRpars(Example_Dataset, NR_pars1, Parm1, "excel", "test.xls")

```
