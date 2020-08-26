# MATLAB function `export_dataset.m`

## Usage

This function is more or less intended for end-users who prefer Excel to view and manipulate data. The code calls MATLAB's xlswrite function to write the [dataset structure](DatasetStructure.md) to an Excel file. Data is written on several sheets: 

* _Dataset_ = a high level summary of the whole test 
* _Format_ = file format information for each media 
* _Read_ = how to read each media 
* _MOS_ = subjective ratings
* _Category_name_ = names of the 8 categories
* _Cateogry_list_ = unique values available for each category
* _Category_ = all 8 category values for for each media

On each page except for _Category_list_, the first row contains field names within the [dataset structure](DatasetStructure.md).

## Details

We note that the end user must supply `nr_dataset`, a variable that conforms to the [dataset structure](DatasetStructure.md). This structure is created by [import_dataset](ImportDataset.md). That page also describes the intended workflow for creating dataset structures. `filename` is the name of the file we're writing the Excel file to. There are no checks for whether the file already exists or not. 

In general, the code proceeds as follows:

Create a MATLAB Cell Array and initialize the first row of the cell array to be cells of strings. This first row acts like a table header, and the relevant data is written in the columns underneath. 

Several such such cell arrays are created, and then written in separate sheets in the Excel file. 
Care must be taken to retain the format of the Excel spreadsheet.

See also [import_dataset](ImportDataset.md).

## Inline Documentation
```text
EXPORT_DATASET
  Export dataset into an XLS file, to be reviewed and checked
 SYNTAX

   export_dataset(nr_dataset, filename)

 SEMANTICS

   Export dataset structure `nr_dataset` to MS-Excel file `filename`
   Intended to help the user easily review and understand the dataset categories
   If `nr_dataset` is empty (i.e., []), export an empty dataset.
```
