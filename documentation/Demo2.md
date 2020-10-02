# Demo 2: Write an NR Feature Function

This tutorial describes how to create a no-reference feature function (NRFF).

## Preliminaries

This demo assumes that you have already gone through [Demo #1](Demo1.md) and calculated several parameters that you'd like to use to generate a metric. In general, it is easier to have all parameters loaded into the workspace before starting. See [Demo #1](Demo1.md) for **definitions**.

***

## No-Reference Feature Function Syntax

The full specification of a NRFF is given in [calculate_NRpars](CalculateNRpars.md). NRFFs are intended to be used in conjunction with [calculate_NRpars](CalculateNRpars.md). Basically, the following function calls must be implemented:

```matlab
   [feature_group]     = feature_function('group')
   [feature_names]     = feature_function('feature_names')
   [parameter_names]   = feature_function('parameter_names')
   [bool]              = feature_function('luma_only')
   [duration]          = feature_function('read_mode')
   [feature_data]      = feature_function('pixels', fps, y)
   [feature1_data]     = feature_function('pixels', fps, y, cb, cr)
   [par_data]          = feature_function('pars', feature_data, fps, image_size);
```

While the interface may look daunting, designing a feature function is ultimately not that difficult. The no-reference feature function (NRFF) can be thought of as a giant switch statement that executes differently depending upon the flags that are being passed in. All segments of this switch statement give a value to **data** which is then returned by the function.

We will examine each function call in turn.

### Group
As a trivial example:

```matlab
 function [data] = nrff_test(mode, varargin)
 % name of the feature group

 if strcmp(mode, 'group')
    data = 'test';
```

The 'group' flag returns a name (string) that is used to organize the NR features and NR parameters calculated by this NRFF. The 'group' string is very important and must be unique, because [calculate_NRpars.m](CalculateNRpars.md) uses the `group` string for its directory naming convention. 
Avoid white space and slashes. 

There is no particular formatting required aside from user preference.

### Feature Names
```matlab
 elseif strcmp(mode, 'feature_names')
    data{1} = 'example_feature1';
    data{2} = 'example_feature2';
```

The 'feature_names' flag returns a cell array. Each cell contains the name of one NR feature calculated by this function. 
The NR feature name strings are very important and must be unique, because [calculate_NRpars.m](CalculateNRpars.md) uses these strings in its directory naming convention. 

### Parameter Names
```matlab
elseif strcmp(mode, 'parameter_names')
    data{1} = 'example_parameter';
```

The 'parameter_names' flag returns a cell array. Each cell contains the name of one NR parameter that is calculated by this function. The NR parameter name strings are very important and must be unique, because [analyze_NRpars.m](AnalyzeNRpars.md) and paramtomatrix.m use these strings to identify your NR parameters. 


### Luma Versus Color
```matlab
 elseif strcmp(mode, 'luma_only')
 data = true;
```    

This boolean flag tells [calculate_NRpars.m](CalculateNRpars.md) whether the features are calculated on the luma plane only (true) or whether the calculations require color information (false)

### Read Mode
```matlab 
 elseif strcmp(mode, 'read_mode')
    data = 'si';
```

The `'read_mode'` flag returns the duration of time that the 'pixels' mode requires as input. Use 'si' for spatial information (SI) features, which are calculated for each frame or image separately. Use 'ti' for temporal information (TI) features, which are calculated on sequential pairs of frames, to detect changes over time. Use 'all' for features that are calculated on the entire video (or image) at once. These require the most memory. 

### Calculate NR Features
```matlab  
elseif strcmp(mode, 'pixels')

    fps = varargin{1};
    y = varargin{2};
   
    [~, ~, frames] = size(y);
    if frames ~= 1
        error('This feature must be given exactly 1 frame in the tslice function call');
    end
    % Frame Level Features
    % Calculate Mean Pixel Value of entire image
    data{1, 1} = mean(mean(y)); 
    % Calculate Max Pixel Value of entire image
    data{1, 2} = max(max(y));
```    

The meat of the calculation comes in here. In general, we note that features are
any statistic/factor that derives from a single frame of video (or a single image).
In general, these are things like mean pixel value, or max pixel value, or whatever
the end user would like.

In this example, the 'pixels' function ignores the `fps` input variable, which identifies the frame rate of this media. If the 'luma' flag were false, then two more input parameters would be available:
```matlab
    cb = varargin{3};
    cr = varargin{4};
```

### Calculate NR Parameters
```matlab
elseif strcmp(mode, 'pars')
% Compute the parameters for all frames of data
% compute NR parameters, using mean over time
% use nanmean, for safety

    feature_data = varargin{1,1};
    fps = varargin{2};
    image_size = varargin{3};

    data = nan(1,size(feature_data ,1));
    for cnt=1:size(feature_data ,1)
        data(cnt) = nanmean(squeeze([feature_data {cnt,:}]));
        % clip at 1.5
        data(cnt) = min(data(cnt), 1.5);
    end    
```
In this segment, we calculate the actual NR parameters. In this case, we note that our
input will be provided to the function via [calculate_NRpars](CalculateNRpars.md). We
assume that the features are appropriately calculated and then run some sort of aggregation
across a feature to get one parameter per feature per media. If there are 2 features for each
frame, then the entire video will have 2 parameters.

The above code takes each feature and takes the mean of them across all frames.

***

## Sample NRFFs

To better understand the NRFF interface, we recommend looking at the following functions, provided in this repository and used in this series of demos:

### nrff_auto_enhancement.m
The 'unsharp' group calculates spatial information NR features from color images. 
Each image or video frame is divided into 100 blocks, each similar in size. 
The NR parameter uses the `image_size` input parameter in 'pars' mode to calculate a scaling factor that corrects for the reduced sensitivity of pixels in a 4K monitor compared to pixels in an HD monitor. 

### nrff_blur.m
The `nrff_blur.m` function calculates multiple NR features and NR parameters.
The 'blur' group calculates spatial information NR features from the luma plane that estimate sharpness and blur.
The NR parameters that are based on the unsharp filter divide each image or video frame into 100 blocks, each similar in size. 
The `image_size` input parameter in 'pars' mode is used to calculate a scaling factor that corrects for the reduced sensitivity of pixels in a 4K monitor compared to pixels in an HD monitor. 
The NR parameters that are based on the Laplacian and Sobel filters do not divide the image into blocks, but rather calculate statistics using all pixels. 

### nrff_PanIPS.m
The 'PanIPS' group calculates temporal information (TI) NR features from the luma plane.
This function uses the `fps` input variable in the 'pixel' mode. 
This function calculates two NR features and eight NR parameters. The last two NR parameters contain metrics built upon the prior six NR parameters. 
NR parameter 'PanSpeedNN' contains a neural network that was trained on the PanIPS group's NR features, using the ITS4S4 dataset.
NR parameter 'PanSpeed' contains an alternate metric that was trained on the ITS4S4 dataset using linear regression.
Note that 'PanSpeed' outperforms 'PanSpeedNN' for datasets ITS4S3 and KonVID-1K. The relevant analysis is included below.

```text
7) PanSpeed 
its4s            corr =  0.10  rmse =  0.77  percentiles [ 2.16, 4.11, 4.42, 4.67, 4.67]
its4s3           corr =  0.35  rmse =  0.71  percentiles [ 1.26, 3.79, 4.12, 4.67, 4.67]
its4s4           corr =  0.79  rmse =  0.54  percentiles [ 1.43, 2.73, 3.32, 3.99, 4.67]
konvid1k         corr =  0.34  rmse =  0.60  percentiles [ 1.20, 3.89, 4.67, 4.67, 4.67]

8) PanSpeedNN 
its4s            corr =  0.10  rmse =  0.77  percentiles [-0.96, 4.26, 4.42, 4.42, 6.75]
its4s3           corr =  0.23  rmse =  0.74  percentiles [-0.51, 3.60, 4.33, 4.42, 7.30]
its4s4           corr =  0.81  rmse =  0.52  percentiles [ 1.45, 2.64, 3.31, 4.06, 4.82]
konvid1k         corr =  0.16  rmse =  0.63  percentiles [-1.28, 3.96, 4.42, 4.42, 7.86]
```
