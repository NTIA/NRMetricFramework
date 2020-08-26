# MATLAB function `import_dataset.m`

## Usage

Function import_dataset.m has two distinct execution paths. 
The first path takes a directory of media (images or videos.md) and creates a new [dataset structure](DatasetStructure.md). 
The second path creates a dataset structure from an Excel spreadsheet that was previously created by [export_dataset](ExportDataset.md) 

Taken together, functions import_dataset.m and [export_dataset](ExportDataset.md) create a [dataset structure](DatasetStructure.md) that describes the media and subjective ratings associated with a subjective test. Since subjective tests are complex, this function cannot create a fully correct dataset structure from a single function call. Instead, the expected workflow is as follows:
* Create a new [dataset structure](DatasetStructure.md) with import_dataset.m
* Export the [dataset structure](DatasetStructure.md) to Microsoft Excel with [export_dataset](ExportDataset.md)
* Edit the spreadsheet to specify missing values, like mean opinion score
* Import the [dataset structure](DatasetStructure.md) with import_dataset.m
* Save the [dataset structure](DatasetStructure.md) variable for later use 

Alternatively, the user can manually assign field values in MATLAB. In this case, the user is encouraged to check the validity of the modified structure by exporting the dataset, re-importing it, and comparing the results. 

## Details
### Image and Video Files
When creating a new dataset from a directory of media, ensure that all media are in the actual directory. The code does not have the capability to recursively iterate through subfolders. All images and videos need to be in the given directory. 

The NRmetric repository uses different mechanisms to read the following types of media: 
* Images in JPEG or PNG files
* Videos in uncompressed AVI, YCbCr or RGB format
* Any video file that can be read by MATLAB’s VideoReader function 

The 3rd option is not recommended due to unresolved bugs. See function [read_media.m](ReadMedia.md) and [convert_media.m](ConvertMedia.md) for details.

### Media Names

Some [subjective datasets](SubjectiveDatasets.md) have meaningful media file names that include the dataset name, scene, impairment, etc. Other subjective datasets have cryptic media file names like '3343535739.mp4'. To help researchers, the dataset structure gives each media a nickname (field 'name'.md) that will be displayed to the user instead of the file name. 

### Subjective Test Monitor Size 
Note that subjective ratings include the impact of scaling images and videos to the monitor; and
the resolution of these media files may not match the subjective test monitor.
Therefore, input arguments "display_rows" and "display_cols" specify the size in pixels of the area on the monitor where images and videos were displayed. 
All media will be scaled to this display size. If the aspect ratio does not match, the black border on top/bottom or left/right will be ignored. 
Incorrectly specifying these input parameters will severely reduce the accuracy of any NR metrics trained or tested on the dataset. 

### Valid Region, Black Borders
Videos often have an invalid border of pixels around the edge, that contain black. This border may be large or small. 
NR metrics may yield invalid analyses when applied to this region. 
Thus, dataset structure specifies a valid region for each media (see media struct fields valid_top, valid_left, valid_bottom, and valid_right).
Display_rows and display_cols also impacts the valid region, which is automatically calculated for videos.

Images typically do not have an invalid border of black pixels. The valid region defaults to the entire image, upscaled or down-scaled to the target display (i.e., display_rows and display_cols).
To calculate valid region for image datasets, see function [valid_region_search_no_safety](ValidRegionSearchNoSafety.md)

### Subjective Scores

Function import_dataset.m has no way to assign subjective scores (e.g., MOS, SOS, JND.md). There are several options to import subjective ratings into the data structure. See [Dataset Structure](DatasetStructure.md) to understand this variable before beginning.  

#### Spreadsheet

The first option is to export the dataset into a spreadsheet using [export_dataset.m](ExportDataset.md). Insert the subjective data into the spreadsheet. The dataset will then need to be imported back into MATLAB for usage by the other functions.

#### Manual Assignment

Alternatively, write MATLAB code to assign the subjective data to the appropriate media fields. This option is more complicated and not recommended.

## Inline Documentation
```text
IMPORT_NR_DATASET
   Import an NR dataset from Excel spreadsheet, or create data structure for a new dataset

 SYNTAX

   [nr_dataset] = import_dataset(spreadsheet) 
   [nr_dataset] = import_dataset(directory, dataset_name)
   [nr_dataset] = import_dataset(directory, dataset_name, display_rows, display_cols)

 SEMANTICS

   When the first input variable is an Excel spreadsheet, load the described
   the dataset.  

   When the first input variable is a directory, create a new dataset 
   using the images and videos in that directory. Some values will be
   defaults, so it the dataset structure (returned) should be checked. 

   dataset_name is the name of the new dataset. This should be a short
   string (e.g., 8 characters).

   display_rows and display_cols specify the display area on the
   monitor. That is, the image or video was up-sampled or down-sampled to
   this region during the subjective test. Media processing will include
   this resizing. If not specified, the exact image size will be used, which
   is only valid if pixel-for-pixel display was used. 

   The return value (nr_dataset is a dataset structure that describes
   this subjective test.
```
