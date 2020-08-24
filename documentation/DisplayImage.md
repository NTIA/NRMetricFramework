# MATLAB functions `display_xyt.m` and `display_color_xyt.m`

## Usage

* Image planes (`y`, `cb`, and `cr`) must have coordinates (row,col,time)
* No attempt is made to play videos at the correct speed
* `y` range must be [0..255]
* `cb` and `cr` range must be [-128..127]

## Options

## Subplot

To display the image within the current figure, use the 'subplot' flag. The image will be scaled to the available area, ignoring aspect ratio. 

In the example below, an image is read from the CCRIQ dataset. The luma image is displayed in the top subplot, and the color image is displayed in the bottom subplot. You must first download the CCRIQ dataset (see [subjective datasets](SubjectiveDatasets.md)).
```matlab
load iqa_camera.mat
[y,cb,cr]=read_media('all',ccriq_dataset, 300);
figure(1)
subplot(2,1,1)
display_xyt(y, 'subplot')
subplot(2,1,2)
display_color_xyt(y, cb, cr, 'subplot')
```

## Video Format
By default, videos are assumed to be progressive. To correctly play interlaced videos, specify the 'interlace_lower_field_first' or 'interlace_upper_field_first` flag.
```matlab
display_xyt(y, 'interlace_lower_field_first`);
display_xyt(y, 'interlace_upper_field_first`);
```

## Slow Motion
Specify the 'slowmo' flag to play one frame each second, beeping after each frame. The first frame will be played twice.

In the example below, we read the first ten frames of the 25th media in dataset ITS4S4. This color video is played quickly and then slowly. You must first download the ITS4S4 dataset (see [subjective datasets](SubjectiveDatasets.md)). Note that the playback does **not** try to present correct frame rate. 
```matlab
load vqa_camera.mat
[y,cb,cr]=read_media('frames',its4s4_dataset, 25, 1, 10);
display_color_xyt(y, cb, cr)
display_color_xyt(y, cb, cr, 'slowmo')
```

## Multiple Options
Several of these option flags can be appended to the function call in any order. 

## Inline Documentation
```text
DISPLAY_XYT
 Display a greyscale (luma) image or video from memory to the screen.  
 Image coordinates are x (horizontal), y (vertical), and t (time).  
SYNTAX
 display_xyt(y)
SEMANTICS
 Open a new window and display luma image Y, using square pixels and pixel-for-pixel 
 display.
```

```text
DISPLAY_COLOR_XYT
 Display a color image or video from memory to the screen.  
SYNTAX
 display_xyt(y, cb, cr)
SEMANTICS
 Open a new window and display color (YCbCr) image using square pixels and pixel-for-pixel 
 display.
```

