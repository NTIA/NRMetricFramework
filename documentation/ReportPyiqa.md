# Report on pyiqa

_Go to [Report.md](Report.md) for an introduction to this series of NR metric reports, including their purpose, important warnings, the rating scale, and details of the statistical analysis._ 

Function `nrff_pyiqa.m` calls python in a virtual environment and runs a script to invoke the pyiqa environment. The pyiqa package is an image quality assessment toolbox composed of many features, each with a different set of authors and implementation. The pyiqa suite loads the model specified, executes the model on an image and produces a metric value. The pyiqa suite was downloaded and run from [the pyiqa PyPi page](https://pypi.org/project/pyiqa/) as described in [[54]](Publications.md). Pyiqa itself downloads models from the various author's repositories, and is a framework for integrating different metrics into one software package. The research team accessed pyiqa from March 2025 to May 2025, using the most current version of each metric, with pyiqa having a version of 0.13. As time progresses and more metrics are added, or current metrics are improved upon, this assessment of pyiqa may not hold accuracy.

The goal is to determine whether the features calculated by pyiqa can be used for RCA or to predict MOS in general.

## Algorithm Summary
Function nrff_pyiqa implements a framework for calling the pyiqa toolbox and evaluating one selected metric from the list of available metrics. The metrics called from the pyiqa toolbox can have a varied purpose, however we are interested in each metric's ability to provide root cause analysis, or as a predictor of general MOS.

Goal|Metric Name|Rating
----|-----------|------
MOS|pyiqa|:question:

## Speed and Conformity

Function `nrff_pyiqa.m` calls the software toolbox, pyiqa, produced by the authors Chaofeng Chen and Jiadi Mo, documentation available [here](https://iqa-pytorch.readthedocs.io/en/latest/).

The nrff function calls pyiqa within a python virtual environment, pyiqa then downloads an IQA model produced by various research teams. Once the metric is instantiated, an image is passed to the metric, a rating is produced, MATLAB uptakes and parses the data, and the virtual environment is closed. 

The pyiqa toolbox is not very fast in the CPU only environment. The research team integrated pyiqa into MATLAB, which calls a virtual python environment that instantiated and closed for each image. This method proved to be much slower than the equivalent metric implemented natively in MATLAB. An example used was BRISQUE, where the MATLAB implementation ran for about 1.25 seconds per image, while the python virtual environment used anywhere from 70 to 120 seconds per image. The python implementation accepts a directory of images, which was thought to be faster, without the need to instantiate the python environment and load up the model for each image processed. This method only decreased the computation time toward 70 seconds per image in the case of BRISQUE, and 120 seconds per image avg for other metrics. The order of magnitude computation time is consistent with all of the no reference metrics in pyiqa, with the fastest computation time from BRISQUE, and the worst case of MANIQA of 289 seconds. Unfortunately, the computation time is far too long to process video clips, even with a reduced frame-rate. 

This nrff feature function was not designed with usability in mind, and was scripted just for evaluation purposes. The nrff feature function therefore does not save the NR features or NR parameters in a standard format, and therefore the NRpars MATLAB file must be deleted for each new metric evaluated.


## Analysis

The research team cherry picked features to test for an average run time per frame, and found about the same order of magnitude processing time between features. This makes sense, as the pyiqa toolbox is pytorch based, intended to be run on a CUDA device, while all features run by the research team were evaluated on a CPU. Due to the run speed, the research team was only able to run a trimmed down portion of the LIVE VQC tiny dataset in a reasonable amount of time. No feature has been evaluated for pearson correlation, it is possible in the future when a GPU is available the research team will re-evaluate the features against MOS. Below is a chart of all the NR features and the evaluated computation times. Features that have not been evaluated for pearson correlation were given a question mark. 

Feature|Mean Run Time per Image|Rating
----|----------|------
arniqa|158.837919|:question:
arniqa-clive|137.536656|:question:
arniqa-csiq|128.648726|:question:
arniqa-flive|124.238919|:question:
arniqa-kadid|----|:question:
arniqa-live|----|:question:
arniqa-spaq|----|:question:
arniqa-tid|----|:question:
brisque|72.8s|:question:
brisque_matlab|----|:question:
clipiqa|----|:question:
clipiqa+|157.873657|:question:
clipiqa+_rn50_512|----|:question:
clipiqa+_vitL14_512|----|:question:
cnniqa|----|:question:
dbcnn|----|:question:
entropy|95.337146|:question:
hyperiqa|----|:question:
ilniqe|----|:question:
laion_aes|----|:question:
liqe|116.533024|:question:
liqe_mix|----|:question:
maniqa|289.359419|
maniqa-kadid|----|:question:
maniqa-pipal|----|:question:
musiq|187.225388|:question:
musiq-ava|----|:question:
musiq-paq2piq|----|:question:
musiq-spaq|----|:question:
nima|137.531044|:question:
nima-koniq|----|:question:
nima-spaq|----|:question:
nima-vgg16-ava|----|:question:
niqe|----|:question:
niqe_matlab|143.302182|:question:
nrqm|----|:question:
paq2piq|84.411501|
pi|----|:question:
piqe|4.410260|:question:
qalign|----|:question:
topiq_iaa|----|:question:
topiq_iaa_res50|----|:question:
topiq_nr|170.380894|:question:
topiq_nr-flive|----|:question:
topiq_nr-spaq|----|:question:
tres|----|:question:
tres-flive|----|:question:
unique|----|:question:
uranker|----|:question:
wadiqam_nr|93.580966|:question:

The PyIQA toolbox has both full reference and no reference metrics, below is a list of all full reference metrics. The research team observed that these metrics run, but did not evaluate them.

    ahiq
    ckdn
    cw_ssim
    dists
    fsim
    gmsd
    lpips
    lpips+
    lpips-vgg
    mad
    ms_ssim
    msswd
    nlpd
    pieapp
    psnr
    psnry
    ssim
    ssimc
    stlpips
    stlpips-vgg
    topiq_fr
    topiq_fr-pipal
    vif
    vsi
    wadiqam_fr

