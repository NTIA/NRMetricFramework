# MATLAB Variable That Describe Dataset
_Version 2.0_

Most functions in this repository operate on datasets. For this to happen, we need a variable that describes an entire dataset. This age describes the format of these MATLAB variables. The software is designed so that most users will not need to manually modify these dataset variables. However, it is wise to understand what information is recorded and how the software expects to interact with these variables.

## Philosophy and Organization

Each dataset is described in a single MATLAB variable, using structures. The top level structure describes one subjective test dataset (see Table 1. **Dataset Structure**). Embedded inside this is a list of that dataset's media (see Table 2. **Media Structure**). Functions [import_dataset.m](ImportDataset.md) and [export_datset.m](ExportDataset.md) provide tools to create dataset structure variables for new subjective tests. 

The dataset structure is designed to offer flexible support for a variety of subjective tests that are suitable for NR metric development. 
Full reference (FR) or reduced reference (RR) metrics are intentionally not supported, because this simplifies many aspects of the software framework. 
The dataset structure includes a version number, so that the structure format can be modified. 
The following aspects of the dataset structure require some additional explanation. 

## Media Download and Path Updates

This GitHub repository holds software, dataset structures, and information.
The media files associated with each subjective dataset must be downloaded separately. 
You are likely to save datasets to different directories than are listed in the provided MATLAB dataset structure variables.

The [subjective dataset](SubjectiveDatasets.md) page lists subjective datasets suitable for NR metric development. 
The `new_nr_dataset.mat` file provided in this repository has dataset structure variables for each dataset on that page.
You must either:
* Manually change the path in each variable; or
* Export each dataset to Microsoft Excel, update the path, load the spreadsheet back into a MATLAB variable, and save the variables to `new_nr_dataset.mat`. See [import_datset.m](ImportDataset.md) for details. 

## Training versus Verification

A critical element of NR metric development is understanding how the metric responds to new stimuli.
We expect all NR metrics to be less accurate when run on images and videos not used for their training. 
The gold standard is independent validation, for example by the Video Quality Experts Group (VQEG).
One solution, popular for machine learning, is to randomly re-partition the data multiple times.
That approach does not meet the needs of multiple party collaborations, for which this repository was designed. 

This repository uses verification data.
That is, 10% of all media are held in reserve to verify the performance of NR parameters and NR metrics on media that are **never** used to train **any** NR parameter or NR metric.
The verification media are marked in category 2 with the categorical value "verify" (see below).

## Subjective Ratings

The dataset structure currently accommodates two types of subjective ratings: mean opinion scores (MOS) from an absolute category rating (ACR) test and just noticeable differences (JND). 

ACR MOSs are not "absolute", despite the name. 
When we include a set of videos into different subjective tests, each using a [1..5] ACR scale, the ratings from each experiment will differ by a gain and offset (see ["An Objective Method for Combining Multiple Subjective Data Sets"](https://www.its.bldrdoc.gov/publications/details.aspx?pub=2578)).
Additionally, the range of MOSs may vary (e.g., [0..1], [1..5], [0..6], [0..11], [0..100]). 
To simplify plotting and other analyses, the dataset structure contains two versions of each media's subjective ratings.
The first is "raw data" which refers to the MOS and SOS values produced by the subjective test. These values are held as reference and not used by any function. 
The second, called MOS and SOS, must be linearly mapped to a [1..5] scale and are used for all later analyses. 

JND values are always relative and as such do not have this problem.

## Categories

Most subjective tests include experiment design variables with multiple factors. 
For example, the [CCRIQ dataset](SubjectiveDatasets.md) contains identical photographs rated on both an HD monitor and a 4K monitor. 

The dataset structure refers to these design variables as _categories_.
They are implemented as **categorical** type variables in MATLAB. 
Eight categories are available. Categories 1 to 4 have constant definitions. Categories 5 to 8 are uniquely defined for each subjective test. 
Each media has a unique value for each of these 8 categories. 
Category analysis helps users understand how performance of an NR parameter or NR metric responds to that variable. 
For example, the CCRIQ dataset can be used to understand whether the NR parameter or NR metric has a bias for 4K monitors (e.g., predicts too low or too high quality).

Categories 1 to 4 are as follows:

_#_ | Description | Categorical Values
--- | --- | ---
1 | Camera vs compression vs error | original, compressed, error
2 | Training vs verification | train, verify
3 | Codec | avc1, avc, hevc, mpeg2, mpeg4, video, jpeg, png
4 | Monitor resolution | qHD, HD, HD+, FHD, QHD, 4K, 5K, 8K

The nearest monitor resolution is selected, using the definitions from the table below. Monitors can be in either orientation (horizontal or vertical).

Resolution | Size
--- | ---
qHD | 960 x 540
HD | 1280 x 720
HD+ | 1600 x 900
FHD |  1920 x 1080, 1900 x 1200
QHD | 2560 x 1440
4K | 3840 x 2160
5K | 5120 x 2880
8K | 7680 x 4320

## Media Names

Some [subjective datasets](SubjectiveDatasets.md) have meaningful media file names that include the dataset name, scene, impairment, etc. Other subjective datasets have cryptic media file names like '3343535739.mp4'. To help researchers, the dataset structure gives each media a nickname (field 'name') that will be displayed to the user instead of the file name. At a minimum, we recommend that media names include the test name as a prefix. 

Dataset CCRIQ contains two sets of MOSs for each image, because each image was rated on a 4K monitor and an HD monitor. In this case, the dataset includes each file twice. Different media names are used to differentiate between the two. The media structure includes the difference in name, monitor resolution, MOS, and SOS. 

# Table 1. Dataset Structure

Field Name | Description
--- | --- 
dataset_name	|The name of the dataset
path|	The absolute file path to the directory that contains the media in this dataset (images or videos)
media | Vector of media structs, one for each media in the directory (see Table 2)
is_mos|	Boolean flag stating whether mean opinion scores (MOS) are available for the dataset
mos_range|	The range of values for the MOS scores (minimum, maximum)
raw_mos_range|	The raw, unadjusted range of values for the MOS scores (minimum, maximum)
category_list|	The list of possible categorical values for the 8 categories. 
category_name|	Short descriptions of the 8 categories 
miscellaneous|	Miscellaneous information
sujson_file| File with sujson format specifying the subjective test. See www.vqeg.org.	
version	| Version number of the dataset

The "miscellaneous" field allows the user to record unforeseen data that this structure cannot otherwise accommodate. 

# Table 2. Media Structure

Notes:
* The valid region for each image or frame is defined after the image or video is scaled to the subjective test monitor.
* The top-left corner of the image or video is (1,1)
* "Start" and "stop" allow frames at the beginning or end of a video file can be ignored without editing 
* Some information in the media structure is recorded for the user but not used by the software in this repository (e.g., dynamic range)

Field Name | Description
--- | --- 
name|	The name of the media
file|	File name (no path)
bitsteam_usable| Boolean indicating whether the bit stream matches the impairments seen during the subjective test 
image_rows|	The adjusted number of rows, when displayed on the subjective test monitor (see "display_rows" input argument to [import_dataset.m](ImportDataset.md)); this may not match the image or video height
image_columns	|The adjusted number of columns, when displayed on the subjective test monitor  (see "display_cols" input argument to [import_dataset.m](ImportDataset.md)); this may not match the image or video width
video_standard|	character array indicating scan format; must be either 'progressive', 'interlace_upper_field_first', or 'interlace_lower_field_first';
fps|	The frames per second (fps) of the video; NaN for images
start|   Start frame number (i.e., the first video frame to be processed); 1 for images
stop|	Stop frame number (i.e., the last video frame to be processed); 1 for images
valid_top|	The top row of the region to be processed
valid_left|	The left column of the region to be processed
valid_bottom|	The bottom row of the region to be processed
valid_right|	The right row of the region to be processed
mos|	The mean opinion score (MOS), scaled to [1..5]; NaN if not available
sos| The standard deviation of scores (SOS), with MOSs scaled to [1..5]; NaN if not available
raw_mos	|The MOS value unscaled (e.g., could be [0..6] or [1..100])
raw_sos	 | The SOS values unscaled
jnd|	The just noticeable difference (JND) score; NaN if not available.
codec| Character array, describing the video codec if known 
profile	 | The video codec profile, if known
dynamic_range | The dynamic range: 'sdr' for standard dynamic range, 'hdr' for high dynamic range
color_space|	The color space of the media (e.g., 'rgb', 'yuv422', 'yuv420')
tv_standard|    Television standard (e.g., 'BT.709')
display_ratio|	The display ratio (e.g., [16 9])
category1 | Categorical value for category #1 (i.e., 'original', 'compressed', or 'error')
category2 | Categorical value for category #2 (i.e., 'train', or 'verify')
category3 | Categorical value for category #3 (i.e., 'av1','avc','hevc','mpeg2','mpeg4','video','jpeg','png')
category4 | Categorical value for category #4 (i.e., 'qHD','HD','HD+','FHD','QHD','4K','5K','8K')
category5 | Categorical value for category #5, levels chosen by user  
category6 | Categorical value for category #6, levels chosen by user  
category7 | Categorical value for category #7, levels chosen by user  
category8 | Categorical value for category #8, levels chosen by user  

## Version Changes 

Version 2 changed the Table 1 field's name from 'test' to 'dataset_name'. 
The field name 'test' caused confusion during debugging. 
This change impacts several functions and all saved data (NRpars and dataset variables). 
