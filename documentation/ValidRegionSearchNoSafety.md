# MATLAB Function `valid_region_search_nosafety`
## Usage

This function is used to calculate the valid region of an image of a sequence of images (a video.md). This function is internally called by [import_dataset](ImportDataset.md) and is exposed to the user for application on image data sets. 

## Details

This function is intended to calculate the valid region of an image. The valid region is specifically the region of the image without a black border. Indeed, this function can be thought of as a function that reports the region of the border (if one exists) and the region of the actual image. This function was primarily designed to interact with individual frames of video, but can also be used on images. General usage is:

```matlab
>> image = imread('test_image.jpg');
>> [bottom, right] = size(image);
>> [top, left, bottom, right] = valid_region_search_nosafety(image, 1, 1, bottom, right);
```

## Inline Documentation
```text
 VALID_REGION_SEARCH_NOSAFETY
   This is a function that calculates a valid region for one imamge.That
   is, area that isn't a black border. Function aims to remove black
   borders from videos. This calculation has no safety margin at the edge,
   and so will not work properly for old videos containing closed
   captioning in the overscan.

 USAGE
   Function takes the Luma plane of the YCbCr image and outputs the valid
   region coordinates.

   y - the luma plane of the YCbCr frame or image.
   min_top - the min value we'd like the top y value to be
   min_left - the min value we'd like the top x vlaue to be
   min_bottom - the min value we'd like the bottom y value to be
   min_right - the min value we'd like the bottom x value to be

   [top_corner_y, top_corner_x, bottom_corner_y, bottom_corner_x] =
   valid_region_search_nosafety(y, 0, 0 , 100, 100);

 SEMANTICS
   In general, this function works by taking the average of the pixel
   values of the rows and columns and taking the mode of the vector of
   average row values and the mode of the average column values. The idea
   is that in natural 'normal' video, the border will be uniform color and
   rectangular at the top and bottom. In this way, the mode should then
   capture the pixel value of the row and column if it is a border (it is
   unlikely you will have lines of solid color in a normal video).

   The average column and row values are then compared to this mode value
   to determine if each column or row is a border row or not. We start on
   the outside and move inwards, stopping once the column/row value
   deviates to far from the mode value.

   Also, if a row is a solid black line, the std deviation should be low,
   (close to 0, if not exactly 0), therefore we also put a std deviation
   threshold to decide if each row/column is a border or not.
```
