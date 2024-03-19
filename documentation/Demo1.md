# Demo #1: Download Datasets, Calculate NR Parameters, and Analyze Performance 

This page demonstrates the workflow to run and analyze another developer's NR parameters.
This is part one of a four part tutorial that demonstrates capabilities of the NRMetricFramework repository. 

### Definitions
* **Mean Opinion Scores (MOS)** estimate overall quality; the usual range is [1..5] where 1 is bad and 5 is excellent.
* **Root cause analysis (RCA)** provides a systematic analysis of impairments. Why is the quality bad? How could the media be improved?
* **NR features** are frame or region level statistics that hold intermediate calculations (e.g., local estimate of blurring).
* **NR parameters** are media level statistics that provide RCA for one impairment (e.g., how blurry is this video?)
* **NR metrics** predict overall quality, usually MOS.
* **No Reference Feature Functions (NRFF)** calculate a **group** of related NR features and NR parameters.

See ["Open Software Framework for Collaborative Development of No Reference Image and Video Quality Metrics"](Publications.md) to learn why RCA is critical and how to develop NR features and NR parameters.

## Step 1. Organize Training Data

Download the [subjective dataset](SubjectiveDatasets.md) CCRIQ. 

Extract the dataset to your documents folder. For example, on a Windows computer the path to the dataset is as follows:

'C:\Users\<username>\Documents\CCRIQ_distribution'

This repository contains several variables that describe entire datasets. 
Load the CCRIQ Dataset variable and print it, using the code below.

```matlab
>> clear;
>> load iqa_camera.mat;
>> ccriq_dataset

ccriq_dataset = 

  struct with fields:

     dataset_name: 'ccriq'
             path: '\\itsvideo\Gold\All_Video_Tests\avi__ccriq\images\'
            media: [1×784 struct]
           is_mos: 1
        mos_range: [1 5]
    raw_mos_range: [1 5]
    category_list: {1×8 cell}
    category_name: {1×8 cell}
    miscellaneous: {}
      sujson_file: ''
          version: 1
```
Update ccriq_dataset.path to be your environment's CCRIQ Dataset path.
```matlab
>> ccriq_dataset.path = 'C:\Users\<username>\Documents\CCRIQ_distribution';
>> save iqa_camera.mat *_dataset;
```
You used the wild card * because file `iqa_camera.mat` contains several variables, each describing a different dataset. 
If you print variable `ccriq_dataset` again, only the path field will have changed. 
If you see any other changes to the variable `ccriq_dataset`, download `iqa_camera.mat` from the GitHub repository and start Demo1 again. 

## Step 2. Calculate NR Features and NR Parameters

For this demo, we will use the no-reference feature function (NRFF) `nrff_blur.m` which measures blurring in images.

The below code runs the NRFF on the CCRIQ dataset to calculate features. Either run these NRFF on the CCRIQ dataset or download the data from repository file `demo1.zip` into directory `C:\nr_data\`. 

```matlab
>> base_dir = 'C:\nr_data\';
>> calculate_NRpars(ccriq_dataset, base_dir, 'stimuli', @nrff_blur);
```
The function `calculate_NRpars.m` creates a sub-directory 'group_blur' underneath the base directory with the following contents:

* .\group_blur\features\ 
* .\group_blur\NRpars_blur_ccriq.mat

`nrff_blur.m` calculates two NR features:

* _unsharp_ 
* _viqet-sharpness_, 

and saves them to `[base_dir 'group_blur\features']` in subdirectories with the NR feature's name. The feature data for each media is saved to a *.mat file named after the media.
* .\group_blur\features\laplacian-above90%\ 
* .\group_blur\features\sobel-std\
* .\group_blur\features\Y_unsharp_above95%\
* .\group_blur\features\Y_unsharp_range\ 

File **NRpars_blur_ccriq.mat** contains the NR parameters calculated by `nrff_blur.m` for the dataset CCRIQ.

To examine the NR parameter variable format using the MATLAB variable window, execute
```matlab
>> load([base_dir 'group_blur\NRpars_blur_ccriq.mat'])
```
to obtain variable `NRpars`. This structure contains the parameter names, media names, parameter values, the dataset name, and other relevant information.

## Step 3. Analyze NR Parameters

Function [analyze_NRpars.m](AnalyzeNRpars.md) analyzes the performance of the NR parameters calculated by one NRFF. Function `nrff_blur.m` calculates two NR parameters, _unsharp_ and _viqet-sharpness_. To analyze _blur_, execute:

```matlab
>> analyze_NRpars(ccriq_dataset, base_dir, @nrff_blur, 'plot');

NRFF Group blur

--------------------------------------------------------------
1) unsharp 
ccriq            corr =  0.61  rmse =  0.81  percentiles [ 0.55, 1.50, 1.84, 2.17, 3.16]

average          corr =  0.61  rmse =  0.81
--------------------------------------------------------------
2) viqet-sharpness 
ccriq            corr =  0.67  rmse =  0.76  percentiles [ 2.19, 4.13, 5.01, 5.95, 7.28]

average          corr =  0.67  rmse =  0.76
```

The function [analyze_NRpars.m](AnalyzeNRpars.md) calculates:
* Pearson correlation
* Root mean square error (RMSE)
* NR parameter value percentiles (0%, 25%, 50%, 75%, and 100%)
* A scatter plot (not shown) 

Note that [analyze_NRpars.m](AnalyzeNRpars.md) only uses the **training data** for this analysis. 10% of CCRIQ's images are set aside as **verification data**. See the [dataset structure](DatasetStructure.md) discussion of training and verification for more information.

### Categorical Comparison

We will now compare the performance of _blur_ for the CCRIQ dataset's main design variable: monitor resolution. 

First, we will find out what [categories](DatasetStructure.md) are available for the CCRIQ dataset using the *'info'* flag to **analyze_NRPars**.

```matlab
>> analyze_NRpars(ccriq_dataset, base_dir, @nrff_blur, 'info');

Available categories for analysis:
Dataset ccriq
- Category 4 - 4K FHD 
- Category 5 - PhoneTablet Compact DSLR 
- Category 6 - FullSun Indoor Dim Night 
- Category 7 - A B D E F G H I J K L M N O P Q R S T U V W X 
- Category 8 - AutumnMountains BeachToys BouquetDimClose BuildingNightFlashDisabled DenverBotanicGardensGreenhouse EvacuationPlan FlowerSpotFlashDisabled FLowerSpotFlashDisabled GolfCourse Lady&Fence Lady&FenceFlashDisabled Lady&Metal Lady&MetalFlashDisabled MachenIllustrationsFoxStBridge MarthaDanielPainting MirrorBallConfetti ParkingNight1 Sushirolls WinterPeaks 
```
For each category, `analyze_NRpars.m` lists available options.

We want category four, monitor resolution.

The below MATLAB command analyzes _blur_ for the CCRIQ dataset, split by monitor resolution, and creates three plots: 

* Overall
* FHD monitor
* 4K monitor 

These plots and statistics indicate whether the NR parameter has any particular biases toward 4K monitor displays. 

```matlab
>> analyze_NRpars(ccriq_dataset, base_dir, @nrff_blur, 'plot', 'category', 4);

Loading NR parameters. This will be very slow, if not yet calculated
blur already calculated for ccriq

NR parameters loaded

*************************************************************
NRFF Group blur

--------------------------------------------------------------
1) unsharp 
ccriq            corr =  0.61  rmse =  0.81  percentiles [ 0.55, 1.50, 1.84, 2.17, 3.16]

average          corr =  0.61  rmse =  0.81


Analyze by Camera Type

PhoneTablet      corr =  0.67  rmse =  0.74  percentiles [ 0.86, 1.47, 1.80, 2.13, 3.09]
Compact          corr =  0.56  rmse =  0.87  percentiles [ 0.55, 1.52, 1.88, 2.17, 3.16]
DSLR             corr =  0.54  rmse =  0.78  percentiles [ 0.93, 1.53, 1.88, 2.25, 3.10]
--------------------------------------------------------------
2) viqet-sharpness 
ccriq            corr =  0.67  rmse =  0.76  percentiles [ 2.19, 4.13, 5.01, 5.95, 7.28]

average          corr =  0.67  rmse =  0.76


Analyze by Camera Type

PhoneTablet      corr =  0.71  rmse =  0.69  percentiles [ 2.29, 3.97, 4.92, 5.82, 7.28]
Compact          corr =  0.61  rmse =  0.84  percentiles [ 2.19, 4.34, 5.12, 5.95, 7.04]
DSLR             corr =  0.61  rmse =  0.73  percentiles [ 2.98, 4.37, 5.21, 6.27, 7.17]
```

When `nrff_blur.m` has been calculated for multiple datasets, `analyze_NRpars.m` creates a table that allows comparisons between datasets. The full report is provided. In this example, we omit the optional plots.

```matlab
>> analyze_NRpars([bid_dataset ccriq_dataset cid2013_dataset cv_dataset its4s2_dataset livewild_dataset], base_dir, @nrff_blur);

Loading NR parameters. This will be very slow, if not yet calculated
blur already calculated for bid

blur already calculated for ccriq

blur already calculated for cid2013

blur already calculated for C&V

blur already calculated for its4s2

blur already calculated for LIVE-Wild

NR parameters loaded

*************************************************************
NRFF Group blur

--------------------------------------------------------------
1) unsharp 
bid              corr =  0.51  rmse =  0.87  percentiles [ 0.70, 1.32, 1.60, 1.77, 2.42]
ccriq            corr =  0.61  rmse =  0.81  percentiles [ 0.55, 1.50, 1.84, 2.17, 3.16]
cid2013          corr =  0.73  rmse =  0.61  percentiles [ 0.00, 1.66, 1.93, 2.19, 2.88]
C&V              corr =  0.50  rmse =  0.62  percentiles [ 0.77, 1.75, 1.93, 2.07, 2.37]
its4s2           corr =  0.55  rmse =  0.62  percentiles [ 0.68, 1.60, 1.86, 2.05, 2.68]
LIVE-Wild        corr =  0.49  rmse =  0.71  percentiles [ 0.74, 1.82, 2.02, 2.18, 2.71]

average          corr =  0.57  rmse =  0.71
pooled           corr =  0.49  rmse =  0.77  percentiles [ 0.00, 1.61, 1.88, 2.10, 3.16]

--------------------------------------------------------------
2) viqet-sharpness 
bid              corr =  0.47  rmse =  0.90  percentiles [ 2.33, 4.29, 5.05, 5.64, 7.43]
ccriq            corr =  0.67  rmse =  0.76  percentiles [ 2.19, 4.13, 5.01, 5.95, 7.28]
cid2013          corr =  0.74  rmse =  0.61  percentiles [ 1.00, 5.20, 5.79, 6.35, 7.70]
C&V              corr =  0.46  rmse =  0.64  percentiles [ 2.94, 5.18, 5.89, 6.20, 7.12]
its4s2           corr =  0.61  rmse =  0.59  percentiles [ 2.09, 4.70, 5.54, 6.17, 7.73]
LIVE-Wild        corr =  0.49  rmse =  0.71  percentiles [ 2.32, 5.06, 5.73, 6.29, 7.99]

average          corr =  0.57  rmse =  0.70
pooled           corr =  0.54  rmse =  0.74  percentiles [ 1.00, 4.66, 5.51, 6.15, 7.99]
```

Note that each dataset's MOSs are linearly scaled to [1..5] to simplify the statistics, plots, and pooling demonstrated above. 

## Step 4. Export Parameters for Greater Flexibility
Alternatively, you can export the NR parameters to either a spreadsheet or local variables. 
This command exports the blur metrics for the CCRIQ dataset to file 'MetricValues.xls': 
```
>> export_NRpars(ccriq_dataset, base_dir, @nrff_blur, 'MetricValues.xls');
```
And this command exports the same information to local variables. 
```
>> [values, mos, par_name, media_name] = export_NRpars(ccriq_dataset, base_dir, @nrff_blur, 'MetricValues.xls');
```
Variable `values` has the metric values, `mos` the mean opinion scores, `par_name` the parameter names, and `media_name` the names of the media. 
See the help for function [export_NRpars.m](export_NRpars.md) for details.

Note that `export_NRpars.m` by default returns the __training media__ (approximately 90%).
The remaining 10% must be held in reserve for metric verification (i.e., as a last calculation immediately before publishing a self-reported accuracy). 
This verification data must not be used for machine learning training / testing cycles. 

## Step 5. Modify and Repeat

NR parameter analysis will reveal problems with the NR features and NR parameters. For example, [analyze_NRpars.m](AnalyzeNRpars.md) provides options to apply a square or square root before analysis, to remove non-linearities. 

If this provides satisfactory results, the square or square root function can be added to the NR parameter calculation to update the parameters. For an example, see the `nrff_blur.m` code, mode `'pars'`.

To re-calculate NR parameters without re-calculating NR features, we need to delete the NR parameter files. 
We will use function [update_NRpars.m](UpdateNRpars.md) with option 'update_pars'.
To erase the NR parameter files that we created in Step 2 ('NRpars_blur_ccriq.mat'), execute
```
update_NRpars(base_dir, @nrff_blur, 'update_pars');
```
The NR parameter files can be erased manually. 
Navigate to `base_dir` and then NR parameter's sub-directory.
The naming convention for NR parameters is NRpars_<group>_<dataset_name>.mat, where <group> is the name of the NR parameter group and <dataset_name> is the name of the dataset (e.g., ccriq). 

We recommend only erasing the NR feature files if the feature function changes. 
NR parameters are fast to calculate, but NR features are slow to calculate. 
NR features must be erased manually, by deleting the `features` sub-directory.

## Appendix. NR Features for Programmers

Most people will never need to load and examine NR features. Function `calculate_NRpars.m` does this for you.

If you want to examine the NR feature variable format, execute
```matlab
>> load([base_dir 'group_blur\features\Y_unsharp_range\ccriq_AutumnMountains_A-4k_phon_1mp.mat'])
```
to obtain variable `data` with size (1,1,1,99). The first dimension is always one (1). The second dimension, time, is one unit long because CCRIQ contains images. The 3rd and 4th dimension hold the NR feature data, here a (1,99) vector. _Y_range_ splits each image into roughly 100 regions, using function [divide_100_blocks.m](Divide100Blocks.md).

**ccriq_AutumnMountains_A-4k_phon_1mp** is the name `ccriq_dataset` uses for media file **AutumnMountains_A_phon_1mp.jpg**. The media name includes two pieces of information missing from the file name: the test name (CCRIQ) and whether the image was displayed on a 4K or HD monitor. See the [dataset structure](DatasetStructure.md) page a discussion of media names.
