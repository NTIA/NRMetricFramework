# MATLAB function divide_100_blocks.m


## Usage

This function is generally called by No-Reference Feature Functions (NRFF) to create a grid of ≈100 blocks, all roughly the same size. Typically, the NRFF would analyze each block separately, to capture anomalies and impairments at a lower level of granularity. These are often important when designing features.

## Details

The ideal is to divide the image into 100 squares. Due to irregularities in image size after scaling to the monitor, the block sizes are often irregular (rectangles), the count may be slightly higher or lower than 100, and some blocks may have more or less pixels than others. 
The function does some rounding (floor, raw, ceil) and finds the increment along each axis that gives closest to one hundred blocks.


## Inline Documentation
```text
 divide_100_blocks
   Choose blocks that divide an image / video
 SYNTAX
   [blocks] = divide_100_blocks(rows, cols, cvr)
 SEMANTICS
  The idealized goal is to divide the image into 100 squares. This
  function makes compromises, based on the realities of an uneven valid
  region. Blocks are rectangles, and some blocks may have more
  pixels than others. Fewer than 100 blocks may be returned.

 Input variables
   'rows'
   'cols'          Size of the image displayed on the monitor.
   'extra'         Extra pixels needed around all blocks for processing.

 Output variables
   'blocks'            An array length N, each element a structure 
                       describing one block.
   'blocks().pixels'   Number of pixels in this block
   'blocks().top'      Top row of the block
   'blocks().left'     Left column of the block
   'blocks().bottom'   Bottom row of the block
   'blocks().right'    Right column of the block
```
