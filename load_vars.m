% This script loads dataset variables and establishes a few commonly used
% variables. The user is encouraged to modify this file to suit your needs.

% Add the reports sub-directory to the MATLAB executable search path
addpath('.\reports\');

% Variable points to a directory where features are stored.
base_dir = '\\itsvideo\Gold\new_features';

% load the Image Quality Analysis (IQA) datsets with camera impairments
load iqa_camera.mat

% Establish a variable that lists all IQA datasets with camera impairments
iqa_cam_ds = [ bid_dataset ccriq_dataset cid2013_dataset cv_dataset ...
    its4s2_dataset itsnoise_dataset koniq10k_dataset livewild_dataset mui2018_dataset ];

% load the Video Quality Analysis (VQA) datsets with camera impairments
load vqa_camera.mat; 

% Establish a variable that lists all VQA datasets with camera impairments
vqa_cam_ds = [its4s3_dataset its4s4_dataset konvid1k_dataset konvid150kb_dataset ];

% load the Video Quality Analysis (VQA) datsets with broadcast impairments
load vqa_broadcast.mat; 

% Establish a variable that lists all VQA datasets with broadcast
% impairments (e.g., more compression artifacts, less camera impairments)
% 
% Most people will need to replace 'vqegHDcuts_dataset' and 'vqegHD_dataset'
% with 'vqegHDcutspublic_dataset' and 'vqegHDpublic_dataset'
% These variables contain videos that are only available to organizations 
% who were involved in the VQEG HD tests. The extra videos cannot be distributed.
vqa_bc_ds = [its4s_dataset and_dataset vqegHDcuts_dataset vqegHD_dataset youkuv1k_dataset];

% Load the simulated datasets. This is currently just vcrdci_dataset
load simulated.mat


% Load computer vision datasets. Calaster_dataset, and the unavailable diqa datasets
load cv.mat

[sim_ds] = [vcrdci1_dataset vcrdci2_dataset vcrdci3_dataset];
