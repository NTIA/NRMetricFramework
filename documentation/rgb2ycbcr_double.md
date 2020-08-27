# MATLAB function rgb2ycbcr_double

## Usage

This function can be called several ways. 

You can separate the three color planes (red, green, and blue) into three separate variables (`r`,`g`, and `b`), and return the YCbCr color planes in three separate variables (`y`, `cb`, and `cr`).
```matlab
>> [y, cb, cr] = rgb2ycbcr_double(r, g, b);
```

If converting an image, all three color planes can be in a single variable. The 3rd dimension will be the color plane.
```matlab
>> [ycbcr] = rgb2ycbcr_double(rgb);
```

To mix and match these two modes, use optional flags 'ycbcr' and 'y_cb_cr':
```matlab
>> [ycbcr] = rgb2ycbcr_double(r, g, b, 'ycbcr');
>> [y_cb_cr] = rgb2ycbcr_double(rgb, 'y_cb_cr');
```

By default, this function assumes 8-bit values in the range [0..255]. If your input variable is in the range [0..1], append the optional flag 'img'. In this example, the RGB image is on the range [0..1] and we want to split this into three separate image planes. 
```matlab
>> [y, cb, cr] = rgb2ycbcr_double(rgb, 'img', 'y_cb_cr');
```

Similarly, this function assumes the Cb and Cr planes range from [0..255]. If you want Cb and Cr to be centered around zero, with range [-128..127], use the optional flag '128'.
```matlab
>> [ycbcr] = rgb2ycbcr_double(rgb, '128');
```

## Inline Documentation
```text
 RGB2YCBCR_DOUBLE
   Convert image from RGB space into YCbCr space
 SYNTAX
   [ycbcr] = rgb2ycbcr_double(rgb);
   [y, cb, cr] = rgb2ycbcr_double(r,g,b);
   [...] = rgb2ycbcr_double(...,'Flag',...);
 DESCRIPTION
  Takes 'rgb', an (M,N,3) RGB double precision image, and converts 
  'rgb' into an YCbCr image, 'ycbcr'.  Alternately, each image plane may 
  be passed separately, in 'r', 'g' and 'b' input arguments.  
  By default, the return image format will be the same as the input image 
  format (i.e., one variable vs each plane separately)

  Nominal input Y values are on [16,235] and nominal input Cb and Cr values 
  are on [16,240].  RGB values are on [0,255].  This routine does not
  round final RGB values to the nearest integer.
  
  The following optional arguments may be specified: 
 
  '128'    Return Cb and Cr values on a range from -128 to 127. 
           By default, Cb and Cr range from [0..255]
  'img'    Input variable 'rgb' is in 'img' format, as per imread
           (i.e., [0..1] instead of [0..255]
  'ycbcr'  Return matrix size (M,N,3), where (:,:,1) contains the Y
           plane, (:,:,2) Cb, and (:,:,3) Cr.
  'y_cb_cr' Return Y, Cb and Cr planes in three separate variables, 
           each size (M,N).


   Reference: 
     Charles Poynton ColorFAQ.pdf (page 15), available from www.poynton.com.
```
