# Demo 4: Describing a New Dataset

This page demonstrates the workflow to import a new dataset. Our goal is to create a variable that fully describes a dataset (e.g., media and subjective ratings). 
This is part four of a four part tutorial that demonstrates capabilities of the NRMetricFramework repository. 

### Definitions
* **Mean Opinion Scores (MOS)** estimate overall quality; the usual range is [1..5] where 1 is bad and 5 is excellent.
* **Standard Deviation of Opinion Scores (SOS)** reports the spread of ratings around each MOS. 
* **Root cause analysis (RCA)** provides a systematic analysis of impairments. Why is the quality bad? How could the media be improved?
* **Dataset** is a set of images or videos, each with a MOS or some sort of number indicating its quality.

## Step 1. Understand Your Dataset

We will use the [CCRIQ](SubjectiveDatasets.md) dataset for this tutorial. Download from the Consumer Digital Video Library (CDVL, www.cdvl.org); keyword search "ccriq". We will assume the CCRIQ dataset has been unzipped and put into directory 'C:\CCRIQ_Distribution\'. 

Before starting, you must understand the dataset design. For CCRIQ, this information is in Section III of [publication 1](https://www.its.bldrdoc.gov/publications/details.aspx?pub=2820). Reading through this paper, you will find the following key information, which could be useful when training or testing NR metrics:

- What type of media? Images.
- What type of impairments?  Camera capture impairments.
- How are media organized? Full matrix of (camera × scene)
- What rating method was used? Absolute Category Rating (ACR) with five levels
- What was the resolution shown to subjects? 4K (3840 × 2160) and HD (1920 × 1080)
- Were the media displayed pixel-for-pixel on the monitor? No, they were rescaled to display. 
- Does the experiment design allow us to split the media into sub-categories? 
	- 18 scene compositions
	- 23 camera types
	- Four camera categories: phone, tablet, compact, and DSLR
	- Five scene categories: flat surfaces, landmarks at night, landscapes with good lighting, portraits, and still lifes
	- Two monitors: 4K and HD 
- Where the media? Subdirectory 'Primary_Study\'
- Where are the MOSs? 'CCRIQ_Primary_Study_data_3labs.xlsx'
 
Other aspects of the experiment design are irrelevant to NR metric development. For example, this subjective test was conducted at three labs. Similarly, we will ignore the CCRIQ secondary study. 
In general, this type of information cannot be modeled by this repository. 

## Step 2. Check Media File Format

This repository has limited ability to read image and video file formats. See section "Details/Image and Video Files" of [ImportDataset](ImportDataset.md) for details. 

CCRIQ contains JPEG files, which are supported. File format conversion is not required.  

## Step 3. Initialize and Organize Media and Variables

Create two MATLAB variables: one with the path to the directory that contains the media and another with the name of our dataset.

```matlab
>> path_name = 'C:\CCRIQ_Distribution\Primary_Study\';
>> dataset_name = 'ccriq';
```

Next, we will run function [import_dataset.m](ImportDataset.md) to initialize our dataset description variable.

If the media had been displayed pixel-for-pixel, we could use the simple function call:
```matlab
>> [test1_dataset] = import_dataset(path_name, dataset_name);
```
However in CCRIQ, the same images were rescaled to two different monitors during the subjective test. So we must split the data into HD and 4K subsets and initialize two variables: 
```matlab
>> display_rows = 1080;
>> display_cols = 1920;
>> [ccriq_hd_dataset] = import_dataset(path_name, dataset_name, display_rows, display_cols);
>> display_rows = 2160;
>> display_cols = 3640;
>> [ccriq_4K_dataset] = import_dataset(path_name, dataset_name, display_rows, display_cols);
```
The `import_dataset.m` reads each image in to memory.

For video datasets, `import_datset.m` command will take a while to run. It must check the edges of the media for invalid black pixels. The region used for later computation is described as the 'valid region'. See [ImportDataset.md](ImportDataset.md) for details.

## Step 4. Export Dataset Variable To Spreadsheet 

The dataset variables `ccriq_hd_dataset` and `ccriq_4K_dataset` are described in [DatasetStructure](DatasetStructure.md). 

However, to more easily understand and modify these variables, we will export them to spreadsheets.
```
>> export_dataset(ccriq_hd_dataset, 'ccriq_hd.xls');
>> export_dataset(ccriq_4K_dataset, 'ccriq_4K.xls');
```

Open these spreadsheets in the app of your choice. These XLS files have seven tabs. Tab 'Dataset' has information in rows. The other six tabs have information in columns. Each column title (or row title, for tab 'Dataset') corresponds to the name of a structure element that is defined in **Table 2. Media Structures** of [DatasetStructure](DatasetStructure.md).

Start by looking at tab 'Read'. This tab contains information about how the media is scaled to the monitor, including the valid region area. When importing a video datasets, look over the valid regions to make sure they look reasonable; our algorithm can make mistakes. Below are the first few lines of tab 'Read' for 'ccriq_hd.xls'.  

file |name|bitstream_usable	|image_rows	|image_cols|	video_standard	|fps	| start	|stop|	valid_top|	valid_left|	valid_bottom|	valid_right
--|--|--|--|--|--|--|--|--|--|--|--|--
AutumnMountains_A_phon_1mp.jpg	|ccriq_AutumnMountains_A-4k_phon_1mp	|FALSE	|2160|	3840|	progressive	| |	1	|1	|1|	1|	2160|	2700
AutumnMountains_B_compct_1mp.JPG|	ccriq_AutumnMountains_B-4k_compct_1mp|	FALSE|	2160|	3840	|progressive | |	1|	1|	1|	1|	2160|	2880
AutumnMountains_D_tab_1mp.JPG|	ccriq_AutumnMountains_D-4k_tab_1mp|	FALSE|	2160|	3840 |	progressive	| |	1|	1|	1|	1|	2160|	3840


## Step 5. Add MOSs
Go to tab 'MOS'. Right now, the variables (and spreadsheets) do not contain MOSs. We want to fix that. 

Here are the first few lines for the 'MOS' tab of the 'ccriq_4K.xls', after we add ratings from file 'CCRIQ_Primary_Study_data_3labs.xlsx'. 

file	|name	|mos	|sos	|raw_mos|	raw_sos|	jnd
--|--|--|--|--|--|--
AutumnMountains_A_phon_1mp.jpg	|ccriq_AutumnMountains_A-4k_phon_1mp	|1.538461538	|0.646886032	|1.538461538	|0.646886032 |	
AutumnMountains_B_compct_1mp.JPG|	ccriq_AutumnMountains_B-4k_compct_1mp	|2.153846154|	0.96715284	|2.153846154	|0.96715284	| 
AutumnMountains_D_tab_1mp.JPG	|ccriq_AutumnMountains_D-4k_tab_1mp	|1.769230769	|0.815239465|	1.769230769	|0.815239465	| 

The mean opinion scores (MOS) that will be used to train NR metrics appear in column 'MOS'. The other values are recorded for future purposes. 

Because CCRIQ was conducted with the 5-level ACR method, the MOS and RAW_MOS columns are identical. 

If the MOSs spanned a different range, like [0..100] or [0..7] or [-3..3], then we would need to linearly re-scale the MOSs onto the [1..5] range. Otherwise, some of the functionality in this repository may fail (especially plotting). In that case, column 'raw_mos' would contain the original (unscaled) MOSs from the experiment, and column 'mos' would contain the MOSs after re-scaling to [1..5]. 

While editing this file, be careful. **The order that media files are listed must be identical on all tabs.** 

## Update your MATLAB Variable
To update our MATLAB variable, run the following command:

```
[ccriq_hd_dataset_MOS] = import_dataset('ccriq_hd.xls');
[ccriq_4K_dataset_MOS] = import_dataset('ccriq_4K.xls');
```
If you want to check your work, the command below will print each media file and its associated MOS.  
```
for cnt=1:length([ccriq_hd_dataset_MOS.media])
  fprintf('%f %s\n', ccriq_hd_dataset_MOS.media(cnt).mos, ccriq_hd_dataset_MOS.media(cnt).file);
end
```

## Add Categories 

Some datasets allow the media to be split into categories, to better understand the response of MOSs to various factors. See [DatasetStructures](DatasetStructures.md) for information on categories and see [analyze_NRpars.m](AnalyzeNRpars.md) for information on how to take advantage of categories when analyzing an NR metric. 

To enable this functionality, category information must be inserted into spreadsheet tabs 'Category' and 'Category_list' and 'Category_name'. 

Tab 'Category_name' has the title for each category. This will be used for reporting in programs like [analyze_NRpars.m](AnalyzeNRpars.md). 

Tab 'Category_list' lists, for eight categories, the valid options. Note categories 1, 2, 3, and 4 have constant definitions. This will allow comparisons across multiple datasets. Categories 5, 6, 7, and 8 can be uniquely defined for the dataset or ignored. 

Category2 randomly splits the media into training (90%) and verification (10%). Do not touch this. Note that machine learning algorithms must further split the training data, for its own training and testing. 

Tab 'Category' lists the category for each media file. Here are the categories for the full CCRIQ dataset, which is distributed with this repository. To see this, execute the command:

```
load iqa_camera.mat; % load the ccriq_dataset variable into memory
export_dataset(ccriq_dataset,'ccriq.xls');
```

file	| name	| Category1	| Category2	| Category3	| Category4	| Category5	| Category6	| Category7	| Category8
--|--|--|--|--|--|--|--|--|--
AutumnMountains_A_phon_1mp.jpg	| ccriq_AutumnMountains_A-4k_phon_1mp	| original	| train	| jpeg	| 4K	| FullSun	| A	| PhoneTablet	| AutumnMountains
AutumnMountains_A_phon_1mp.jpg	| ccriq_AutumnMountains_A-hd_phon_1mp	| original	| train| 	jpeg	| FHD	| FullSun	| A	| PhoneTablet	| AutumnMountains
AutumnMountains_B_compct_1mp.JPG | 	ccriq_AutumnMountains_B-4k_compct_1mp	| original	| train| 	jpeg	| 4K	| FullSun	| B	| Compact	| AutumnMountains
AutumnMountains_B_compct_1mp.JPG | 	ccriq_AutumnMountains_B-hd_compct_1mp	| original	| train	| jpeg	| FHD	| FullSun	| B	| Compact	| AutumnMountains


Note that we have made the following changes, not included in this demo:
- Combined the HD and 4K into a single variable 
- Add '-4k' or '-hd' to each media name, to specify which display was used
- Specified 'original' for category1, since this dataset has camera capture impairments
- Specified 'jpeg' for category3
- Specified the monitor resolution for category4: 4K or full HD (FHD)
- Added categories that allow the CCRIQ media to be sub-divided by lighting condition, scene code, camera type, and scene name. 
- noted that the dynamic range and display ratio on tab 'Format'


To create this file, run the following code:
```
>> load iqa_camera.mat % load variable ccriq_dataset, plus variables that describe other datasets
>> export_dataset(ccriq_dataset, 'c:\temp\ccriq.xls'); % export the CCRIQ dataset into file c:\temp\ccriq.xls
```
