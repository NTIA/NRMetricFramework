# MATLAB function `calculate_NRpars.m`
 
## Usage

Calculate Features is used to calculate NR features and NR parameters. Calculate Features takes a feature function, a [nr_dataset](DatasetStructure.md), and a feature_base_dir as arguments. The feature function must be formatted as specified in the above inline documentation otherwise the code will not properly run. See [Demo #1](Demo1.md) for definitions and see [Demo #2](Demo2.md) for a tutorial on writing feature functions. 

'nr_dataset' is the output from [import_dataset](ImportDataset.md), which can be given as either a single dataset or an array of datasets, and the feature_base_dir is the directory where all the calculated features (and parameters) will be stored. 

## Semantics

Calculate Features has several paths of execution depending on the flags given to the function. These are mostly in regards to parallel processing.

## Inline Documentation
```text
 CALCULATE_NRPARS
   Support tool to calculate a NR feature on all videos or images in a dataset.
 SYNTAX
   [NRpars] = calculate_NRpars(nr_dataset, ...
       feature_base_dir, parallel_mode, feature_function);
 SEMANTICS
   This function provides all support tools needed to calculate
   no-reference (NR) features and NR parameters.
   - NR feature provides multiple values for each image or video.
   - NR parameter provides one value for the entire video or image.
   Other functions will combine NR features and/or NR parameters into NR
   metrics, to provide the user with an overall quality estimation.

 Input Parameters:
   nr_dataset = Data structure. Each describes an entire dataset (name, file location, ...)
   feature_base_dir = Path to directory where NR features and NR parameters are stored.

   parallel_model =
       'none'      Linear calculation. Parallel processing toolbox avoided.
       'stimuli'   Parallel processing on the stimuli level.
       'tslice'    Divide each stimuli into segments for parallel processing
                   Note: tslice mode automatically disabled for images
                   (presented as 1 fps sequences), due to inefficiencies.
       'all'       Do parallel processing on both the stimuli and tslice level.

                   (Note: 'all' and 'stimuli' mode cannot save progress
                   calculating NRpars. Only features can be saved against computer crash.)

   feature_function = Function call to compute the feature.
       This no-reference feature function (NRFF) must adhere to the
       interface specified below.
```


## NR Feature Function Interface
Function `calculate_NRpars.m` takes as an input parameter a function that calculates a set of NR features and NR parameters. That function, assigned to input parameter `feature_function` must have the following interface. See [Demo #2](Demo2.md) for an example. 

```text
FEATURE_FUNCTION
  Input parameter 'feature_function' must have the following interface
      [data] = feature_function(mode, varargin);
          'mode' is a char array specifying the action to be performed
          'data' is a cell array with 1 or more return values.
  Each feature function must implement the following calls:

STANDARD SYNTAX
   [feature_group]     = feature_function('group')
   [feature_names]     = feature_function('feature_names')
   [parameter_names]   = feature_function('parameter_names')
   [bool]              = feature_function('luma_only')
   [duration]          = feature_function('read_mode')
   [feature_data]      = feature_function('pixels', fps, y)
   [feature1_data]     = feature_function('pixels', fps, y, cb, cr)
   [par_data]          = feature_function('pars', feature_data, fps, image_size);

STANDARD SEMANTICS
 'feature_group' mode returns the feature names
   Output
       feature_group = char array (short) uniquely identifying this group
           of features and parameters. 

 'feature_names' mode returns the feature names
   Output
       feature_names = cell array with feature names

 'parameter_names' mode returns the parameter names
   Output
       parameter_names = cell array with parameter names

 'luma_only' mode returns color space option
   Output
       bool = true for luminance only;  
       bool = false if 'pixels' mode tales y, cb, and cr.

 'read_mode' = Type of time-slice (tslice) that 'pixels' call takes as input
               and returns one of the folowing types:
       'si'        1 frame, for spatial information (SI) features 
       'ti'        Overlapping series 2 frames (overlapping by 1F) to
                   calculate temporal information. If interlaced, de-interlace  
                   and group pairs of fields of the same type.
       'all'       The entire stimuli 

 'pixels' mode calculates these features on one tslice
   Input:
       fps = frames per second; NaN for images
       y = image or 1 frame of video, luma only, as a 2D array; 
           more generally, a tslice of video. Vertical & horizontal size 
           may be smaller than the viewing monitor
       cb, cr = Cb and Cr planes associated with luma plane y
   Output:
       feature_data = Cell array, one cell for each feature name.
           Each cell must contain either a single value, vector, or
           2-dimensional matrix. These return variables must be returned
           in same order as the feature names. 

 'pars' mode
   Input:
       fps = frames per second; NaN for images
       image_size = [rows,cols] = Size of image as displayed on the
                   monitor during subjective testing, including black
                   border.
       feature_data = Cell array, one cell for each feature name
           Each cell contain data associated with one feature, all frames. 
           Size is (t), (t, x) or (t, x, y) where  t is tslice number 
           (frame number, for 1F features). Otherwise as returned by
           'pixels' function call. 
   Output:
       [par_data] = array, containing the value for each NR parameter
```


***

## Variant NR Feature Function Interface for NR Metrics
The following variant feature_function is used to combine already calculated data from several other feature_functions into a single NR metric. See [Demo #3](Demo3.md) and [metric Sawatch](ReportSawatch.md) for an example. 

```text 
SYNTAX
  [feature_group]     = feature_function('group')
  [parameter_names]   = feature_function('parameter_names')
  [read_mode]         = feature_function('read_mode')
  [par_data]          = feature_function('compose', nr_dataset, base_dir);
SEMANTICS
  Where NRFF takes as input images or videos and outputs NR features and  
  NR parameters, this NR metric takes as input NR parameters and outputs
  NR metrics. 

'feature_group' mode returns the feature names
  Output
      feature_group = char array (short) uniquely identifying this group
          of features and parameters. 

'parameter_names' mode returns the parameter names
  Output
      parameter_names = cell array with parameter names

'read_mode' = 'metric'
      Function calculate_NRpars.m uses this value ('metric') to select
      the alternate execution path.

'compose' mode  calculates the NR metric.
  Output:
      [par_data] = array, containing the value for each NR parameter or
                   NR metric
```
