# Validation

## Usage
Sub-directory documentation/validation contains spreadsheets with data for software validation purposes. 

The validation folder contains XLS spreadsheets created with function [export_NRpars.m](export_NRpars.md).
These spreadsheets contain the NR parameter data for the [Sawatch metric](ReportSawatch.md),
when run on the [image dataset CCRIQ and video dataset ITS45S](DatasetStructure.md).

This data is intended for people who want to implement some or all of the Sawatch algorithms in a different computer language.  

## Details

The table below shows rows 1 to 11 of file `ccriq_sawatch.xls`, `sheet NRpars`. 
Three significant digits are displayed, to simplify the presentation.

The first three columns show the media file names, MOS, and RAW_MOS. 
MOS and RAW_MOS are identical, because the CCRIQ dataset ratings used the 5-point ACR scale (i.e., no scaling was required).  

The remaining columns show the values of the NR parameters that feed into NR metric Sawatch 
and the values of NR metric Sawatch Version 3.
 
media | mos | raw_mos | S-Blur | S-FineDetail | S-WhiteLevel | S-BlackLevel | S-ColorNoise | S-SuperSaturated | S-Pallid | S-Blockiness | S-PanSpeed | S-Jiggle | dipIQ | Sawatch version 3
-|-|-|-|-|-|-|-|-|-|-|-|-|-|-
ccriq_AutumnMountains_A-4k_phon_1mp | 1.54 | 1.54 | 0.45 | 0.68 | 0.00 | 0.00 | 0.00 | 0.00 | 0.61 | 0.00 | 0.00 | 0.00 | 0.60 | 2.94
ccriq_AutumnMountains_A-hd_phon_1mp | 1.65 | 1.65 | 0.49 | 0.47 | 0.00 | 0.00 | 0.00 | 0.00 | 0.62 | 0.00 | 0.00 | 0.00 | 0.24 | 3.80
ccriq_AutumnMountains_B-4k_compct_1mp | 2.15 | 2.15 | 0.51 | 0.75 | 0.00 | 0.00 | 0.29 | 0.00 | 0.55 | 0.00 | 0.00 | 0.00 | 0.76 | 2.07
ccriq_AutumnMountains_B-hd_compct_1mp | 1.88 | 1.88 | 0.54 | 0.53 | 0.00 | 0.00 | 0.22 | 0.00 | 0.55 | 0.00 | 0.00 | 0.00 | 0.52 | 2.86
ccriq_AutumnMountains_D-4k_tab_1mp | 1.77 | 1.77 | 0.65 | 0.88 | 0.00 | 0.00 | 0.22 | 0.00 | 0.33 | 0.00 | 0.00 | 0.00 | 0.88 | 1.47
ccriq_AutumnMountains_D-hd_tab_1mp | 1.50 | 1.50 | 0.64 | 0.64 | 0.00 | 0.00 | 0.16 | 0.00 | 0.31 | 0.00 | 0.00 | 0.00 | 0.56 | 2.48
ccriq_AutumnMountains_E-4k_compct_5mp | 3.69 | 3.69 | 0.34 | 0.44 | 0.00 | 0.00 | 0.02 | 0.00 | 0.28 | 0.00 | 0.00 | 0.00 | 0.35 | 4.03
ccriq_AutumnMountains_E-hd_compct_5mp | 3.23 | 3.23 | 0.48 | 0.35 | 0.00 | 0.00 | 0.00 | 0.00 | 0.30 | 0.00 | 0.00 | 0.00 | 0.17 | 4.19
ccriq_AutumnMountains_F-4k_dslr_5mp | 3.31 | 3.31 | 0.30 | 0.49 | 0.00 | 0.00 | 0.04 | 0.00 | 0.24 | 0.00 | 0.00 | 0.00 | 0.37 | 3.98
ccriq_AutumnMountains_F-hd_dslr_5mp | 2.77 | 2.77 | 0.45 | 0.42 | 0.00 | 0.00 | 0.00 | 0.00 | 0.27 | 0.00 | 0.00 | 0.00 | 0.13 | 4.22


The table below shows the first eight columns of sheet `M1_F1` of spreadsheet `ccriq_blur.xls`. 
This sheet records the first of four features associated with [nrff_blur.m](ReportBlur.md), which is called `Y_unsharp_above95%`.

The blur algorithm uses function [divide_100_blocks.m](Report100Blocks.md) 
to divide the first media file (image `ccriq_AutumnMountains_A-4k_phon_1mp`) into 99 regions of approximately the same size. 
Each column shows the value of NR feature `Y_unsharp_above95%` for a different region.

Because CCRIQ is an image dataset, this sheet contains two lines: the header and one line of data. 
Sheet `M1_F` of spreadsheet `its4s_blur.xls` (not shown) divides the first video file into 96 regions instead of 99 regions, due to differences in aspect ratio,
and contains 97 rows: 
the header plus one line for each of 96 frames.

media | frame | Y_unsharp_above95%(1) | Y_unsharp_above95%(2) | Y_unsharp_above95%(3) | Y_unsharp_above95%(4) | Y_unsharp_above95%(5) | Y_unsharp_above95%(6)
-|-|-|-|-|-|-|-
ccriq_AutumnMountains_A-4k_phon_1mp | 1 | 4.54 | 13.11 | 0.18 | 0.18 | 0.18 | 0.17

See [export_NRpars.md](export_NRpars.md) for more details of the spreadsheet format.  
