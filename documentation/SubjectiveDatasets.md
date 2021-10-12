# Subjective Datasets

This webpage identifies image quality analysis (IQA) and video quality analysis (VQA) datasets that are particularly suited for NR metric development. Our ideal selection criteria are:
* All media can be downloaded royalty free for research & development purposes
* Simulated and outdated impairments are avoided
* Video sequences are short (e.g., 4 seconds); temporal changes in quality are avoided 
* The dataset implements an [unrepeated scene experiment design](https://link.springer.com/article/10.1007/s41233-019-0026-4)
* The media depict modern camera systems

Datasets labeled **suboptimal** fail to meet these criteria.

Most subjective test have experiment designs that split media into subcategories. For example, the CCRIQ dataset contains identical photographs rated on both an HD monitor and a 4K monitor. Each dataset's available categories are identified and numbered below. The category numbers will let you analyze an NR metric's performance for that factor. See the [dataset structure](DatasetStructure.md) page for details.

## Dataset Variables

The following MAT files contain MATLAB variables that describe datasets. Scroll down for descriptions of these datasets.
* `iqa_camera.mat` = image datasets for camera capture
* `vqa_camera.mat` = video datasets for camera capture
* `vqa_broadcast.mat` = video datasets for broadcast applications
* `diqa_ocr.mat` = document image datasets for optical character recognition

These variables let you run commands on entire datasets. Each variable includes a path to the directory where the media are stored. You must download the media and **update that path**. See the [dataset structure](DatasetStructure.md) for details.

*** 

## Image Quality Assessment (IQA), Camera Capture
These datasets contain images from consumer cameras. The impairments characterize the camera capture pipeline. The mean opinion scores (MOS) are influenced by the scene composition and the photographer. Compression artifacts are typically subtle. 

**Load** `iqa_camera.mat` for [dataset structure](DatasetStructure.md) variables

### **bid**
The Blurred Image Database (BID) contains 582 photographs with camera impairments and diverse subject matter.
* Publication [[37]](Publications.md), see section III
* [Image Download](http://www02.smt.ufrj.br/~eduardo/ImageDatabase.htm)
* Inexact experiment design&mdash;photographs chosen from a private collection, one DSLR 
* Diverse subject matter 
* MATLAB variable: bid_dataset

**Warning:** after downloading the BID dataset, the images must be recompressed with script `recompress_BID.m`. Otherwise, `calculate_NRpars.m` may occasionally produce corrupt data. The issue seems to be related to the file format.

***

### **ccriq**
The Consumer Content Resolution and Image Quality Dataset (CCRIQ) explores the relationship between camera type, scene composition, and monitor resolution. The systematic experiment design is extremely valuable for detecting NR parameter biases.
* [Publication 1](https://www.its.bldrdoc.gov/publications/details.aspx?pub=2820)
* [Publication 2](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3172)
* Download from the Consumer Digital Video Library (CDVL, www.cdvl.org); key word search "ccriq"
* Rigorous experiment design&mdash;identical scene compositions photographed with multiple cameras
* Carefully balanced subject matter
* MATLAB variable: ccriq_dataset
    * Category 4 = monitor resolution (HD vs 4K)
    * Category 5 = lighting (full sun, indoor, dim, night)
    * Category 6 = camera model (23 cameras)
    * Category 7 = camera type (phone & tablet, compact, DSLR)
    * Category 8 = scene composition (18 scenes)

***

### **ccriq2+vime1**
This dataset contains two sessions with different experiment designs: CCRIQ dataset 2 and Video and Image Models for consumer content Evaluation (VIME) dataset 1. Called "cv" for brevity, this small dataset compares two experiment designs for NR research.
* [Publication](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3239) 
* Download from the Consumer Digital Video Library (CDVL, www.cdvl.org); key word search "ccriq2+viqe1"
* Exploratory experiment design&mdash;identical scene compositions photographed with multiple cameras
* **Suboptimal** (loose experiment design yielded unreliable data) 
* Limited subject matter
* MATLAB variable: cv_dataset
    * Category 5 = scene composition (11 scenes)
    * Category 7 = session (ccriq vs vime1)

***

### **cid2013**
The Camera Image Database 2013 (CID2013) explores the relationship between camera type and scene composition.
* Publication [[38]](Publications.md)
* [Download](https://zenodo.org/record/2647033)
* Rigorous experiment design&mdash;identical scene compositions photographed with multiple cameras
* Limited subject matter
* Unusual subjective method 
* MATLAB variable: cid2013_dataset
    * Category5 = scene composition (8 scenes)

***

### **its4s2**
The Institute for Telecommunication Sciences Four Second Dataset Two (its4s2) supplies a large variety of camera capture impairments, subject matter, and scene characteristics.
* [Publication](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3219)
* Download from the Consumer Digital Video Library (CDVL, www.cdvl.org); key word search "its4s2"
* Inexact experiment design&mdash;diverse selection of camera, subject matter, and camera capture impairments 
* Diverse subject matter
* MATLAB variable: its4s2_dataset
    * Category 5 = camera type (phone/tablet, compact, DSLR, unknown)
    * Category 6 = scene (29 broad categories)
    * Category 7 = subject matter topics (14 options)
    * Category 8 = session (15 session themes)


***

### **LIVE Public-Domain Subjective In the Wild Image Quality Challenge Database**
Referred to as **livewild** for brevity, this dataset contains diverse bitmap and RV24 photographs from mobile devices, edited to (500 x 500) pixels. Images 1113.jpg and 1124.jpg are omitted, due to an unexplained difference in image size.
* [Publication](http://live.ece.utexas.edu/research/ChallengeDB/index.html)
* [Download](http://live.ece.utexas.edu/research/ChallengeDB/index.html)
* Inexact experiment design&mdash;various mobile devices and camera capture impairments
* Diverse subject matter
* MATLAB variable: livewild_dataset
    * No categories available

***

## Video Quality Assessment (VQA), Camera Capture
These datasets contain videos from consumer cameras. The impairments characterize the camera capture pipeline. The MOSs are influenced by the scene composition and the videographer. Generally speaking, these datasets include all of the impairments seen in the IQA camera capture datasets, plus new impairments associated with moving video. Reduced bitrates and compression artifacts may exist, but they are not the focus of the experiment.

**Load** `vqa_camera.mat` for [dataset structure](DatasetStructure.md) variables

### **its4s3**
The its4s3 dataset contains 4 second videos depicting public safety scenarios, filmed an a variety of cameras in diverse environments that stress the camera's performance.
* [Publication](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3220)
* Download from the Consumer Digital Video Library (CDVL, www.cdvl.org); key word search "its4s3"
* Exploratory experiment design&mdash;professional videographers recreate common camera capture problems  
* Diverse subject matter
* MATLAB variable: its4s3_dataset
    * Category 4 = camera work (9 categories like helmet camera, handheld, or drone)
    * Category 5 = camera impairment (24 broad categories)
    * Category 7 = session (6 public safety scenarios)

***

### **its4s4**
The its4s4 dataset evaluates a single impairment: camera pans. This challenge dataset provides training data for an NR parameter for root cause analysis (RCA) that evaluates the quality of the camera's pan speed. 
* [Publication](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3233)
* Download from the Consumer Digital Video Library (CDVL, www.cdvl.org); key word search "its4s4"
* Exploratory experiment design&mdash;pans edited from professional footage, plus pans over high resolution photographs
* Diverse subject matter
* MATLAB variable: its4s4_dataset
    * Category 4 =  filmed vs simulated

***

### **konvid1k**
The konvid1k dataset contains a large number of video sequences that include the whole spectrum of available video content and all types of distortions. 
* [Publication1](http://database.mmsp-kn.de)
* [Publication2](https://ieeexplore.ieee.org/document/7965673)
* [Download](http://database.mmsp-kn.de/konvid-1k-database.html)
* Rigorous experiment design&mdash;dataset was designed for NR metric development, using objective video selection criteria
* Diverse subject matter 
* **Suboptimal** (sequences contain temporal changes in quality)
* **Suboptimal** (videos filmed 2004 to 2014, lower quality than contemporary cameras)
* MATLAB variable: konvid1k_dataset
    * No categories available

***

## Video Quality Assessment (VQA), Broadcast Applications
These datasets contain broadcast videos and compression bitrates suitable for broadcast applications. The cameras are typically operated by a professional videographer. When compared to the IQA and VQA camera capture datasets listed above, compression artifacts are more obvious and camera capture impairments are more subtle. 

**Load** `vqa_broadcast.mat` for [dataset structure](DatasetStructure.md) variables

### **its4s**
The its4s dataset contains a simplified adaptive streaming bitrate ladder. The footage was produced by professional videographers with broadcast cameras. The its4s dataset includes some low quality footage that the videographer would normally reject. 
* [Publication](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3194)
* Download from the Consumer Digital Video Library (CDVL, www.cdvl.org); key word search "its4s"
* Exploratory experiment design&mdash;an [unrepeated scene](https://link.springer.com/article/10.1007/s41233-019-0026-4) experiment design with related source sequences (RSRC)
* Diverse subject matter
* MATLAB variable: its4s_dataset
    * Category 1 = camera capture vs compression
    * Category 4 = video format (24fps vs 60fps)
    * Category 5 = scene (4 broad categories that describe scene lighting) 
    * Category 6 = system (original plus five compression bitrates)

### **vqegHDcuts** and **vqegHDcutsPublic**
This faux dataset was created from the Video Quality Experts Group (VQEG) HDTV tests. To better match the optimal criteria at the top of this page, each sequence was cut whenever the content or camera motion changed. The MOS of the entire sequence was assigned to each segment, which adds error to the MOSs. Sequences containing transmission errors were omitted. 

Dataset variable `vqegHDcuts_dataset` includes media that are only available to people who participated in the original VQEG HD test. Dataset variable `vqegHDcutspublic_dataset` includes only media that are publicly available. 
* [Publication #1](https://www.its.bldrdoc.gov/vqeg/projects/hdtv/hdtv.aspx)
* [Publication #2](https://www.its.bldrdoc.gov/publications/details.aspx?pub=3235)
* Download VQEG HD datasets from the Consumer Digital Video Library (CDVL, www.cdvl.org); key word search "vqeghd"
* Conventional experiment design
* Diverse subject matter
* **Suboptimal** (scene reuse, faux MOSs)
* MATLAB variable: vqegHDcuts_dataset (not publicly available)
* MATLAB variable: vqegHDcutspublic_dataset
    * Category 1 = camera capture vs compression
    * Category 3 = codec (mpeg2, avc, or unknown)

### **AND**
The AGH / NTIA / Dolby (AND) dataset was designed to evaluate experiment designs with unrepeated scenes. This dataset contains MPEG2, AVC, and HEVC encodings, each at three different bitrates.
* [Publication](https://link.springer.com/article/10.1007/s41233-019-0026-4)
* Download from [CDVL](https://cdvl.org/members-section/view-file/?id=2957)
* Exploratory experiment design
* Diverse subject matter
* **Suboptimal** (temporal changes in quality)
* MATLAB variable: and_dataset
    * Category 1 = camera capture vs compression
    * Category 6 = codec and bitrate 

***

## Document Image Quality Assessment (DIQA) for Optical Character Recognition (OCR) 
These datasets contain photographs of documents. MOSs are inferred from optical character recognition (OCR) success rates. These faux MOSs are insensitive to some impairments. 

**Load** `diqa_ocr.mat` for [dataset structure](DatasetStructure.md) variables

### **DIQA**
The document image quality analysis (DIQA) dataset contains photographs of documents. Simulated MOSs are calculated by comparing the truth data (actual text) with text produced by OCR algorithms. Three versions of this dataset are available, from each of three different OCR algorithms.
* Publication [[45]](Publications.md)
* [Media](https://lampsrv02.umiacs.umd.edu/projdb/project.php?id=73)
* Rigorous experiment design—identical document photographed repeatedly
* Black text on white paper, surface occasionally visible in the background
* MATLAB variable: **diqaF_dataset** = FineReader OCR
* MATLAB variable: **diqaO_dataset** = Omni OCR
* MATLAB variable: **diqaT_dataset** = Tesseract OCR
    * Category5 = scene (25 documents) 

**Warning** after downloading Part1 and Part2, the images must be renamed and moved into a single directory with script `rename_DIQA.m`. 
