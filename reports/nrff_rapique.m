function [data] = nrff_rapique(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard function calls to calculate rapique data
%  using the rapique algorithm developed by Zhengzhong Tu, Xiangxu Yu, 
%  Yilin Wang, Neil Birkbeck, Balu Adsumilli, Alan C. Bovik from the University of
%  Texas at Austin. 
%  Rapique software is available here: 
%  https://https://github.com/vztu/RAPIQUE
%
%  The IEEE Open Journal of Signal Processing 2021 report is located below:
%  https://arxiv.org/abs/2101.10955
%
%  The Rapique software is available as a matlab demo, which was modified
%  to be run as an nrff feature function.
%
%  Temporary files are generated with FFMPEG and deleted to accommodate the yuv420 file
%  format, ffmpeg must be accessible to system calls.
%
%  This feature function has been run on a trimmed down
%  version of the LIVE_VQC dataset, which we renamed LIVE_VQC_tiny. A
%  dataset file was created for LIVE_VQC_tiny, but was not included in this
%  nrff feature function, as it was a test file.
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% REQUIREMENT
%  This nrff feature function requires FFMPEG to be in the path, 
%  and also requires a directory to store temporary yuv420 files. Below is
%  the directory path used to store temporary files, this path must be
%  modified to the local environment.


% Temporary video file path
% video_tmp = 'C:\Users\rgrosso.labnet\Documents\MATLAB\RAPIQUE\tmp';
video_tmp = 'C:\Users\<USER_ID>\Documents\MATLAB\RAPIQUE\tmp';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'rapique';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')

    
    data{1} = 'Rapique';
    
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'Rapique_mean';
    
    
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
elseif strcmp(mode, 'luma_only')
    data = false; %may be false, colors might give more motion info

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on all frames
elseif strcmp(mode, 'read_mode')
    data = 'all'; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% tell calculate_NRpars to not use parallel_mode
elseif strcmp(mode, 'parallelization')
    data = false; 
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

elseif strcmp(mode, 'pixels')
    fps = varargin{1};
    y = varargin{2};
    cb = varargin{3};
    cr = varargin{4};
    file_path = varargin{5};
    filename = varargin{6};
    

    
    [row,col,frames] = size(y);
    
    if isnan(fps) && (frames == 1)
        warning('media must be minimum of 2 frames');
        return;
    end
    

    % parameters
    algo_name = 'RAPIQUE'; % algorithm name, eg, 'V-BLIINDS'
    data_name = 'LIVE_VQC_tiny';  % dataset name to evaluate eg, 'KONVID_1K'
    write_file = true;  % if true, save features on-the-fly
    log_level = 0;  % 1=verbose, 0=quiet

    % create temp dir to store decoded videos
    if ~exist(video_tmp, 'dir'), mkdir(video_tmp); end
    feat_path = 'mos_files';
    filelist_csv = fullfile(feat_path, [data_name,'_metadata.csv']);
    filelist = readtable(filelist_csv);
    num_videos = size(filelist,1);
    out_path = 'MATLAB/RAPIQUE/feat_files';
    if ~exist(out_path, 'dir'), mkdir(out_path); end
    out_mat_name = fullfile(out_path, [data_name,'_',algo_name,'_feats.mat']);
    feats_mat = [];
    feats_mat_frames = cell(num_videos, 1);

    % init deep learning models
    minside = 512.0;
    net = resnet50;
    layer = 'avg_pool';

    video_name = fullfile(file_path, filename);
    yuv_name = fullfile(video_tmp, join([erase(filename, 'mp4'), 'yuv']));
    fprintf('\n\nComputing features for %d sequence: %s\n', i, video_name);

    % decode video and store in temp dir
    if ~strcmp(video_name, yuv_name) 
        cmd = ['ffmpeg -loglevel error -y -i ', video_name, ...
            ' -pix_fmt yuv420p -vsync 0 ', yuv_name];
        system(cmd);
    end

    % get video meta data
    width = col;
    height = row;
    framerate = fps;

    % calculate video features
    tStart = tic;
    feats_frames = calc_RAPIQUE_features(yuv_name, width, height, ...
        framerate, minside, net, layer, log_level);
    fprintf('\nOverall %f seconds elapsed...', toc(tStart));
    
    feats_mat(1,:) = nanmean(feats_frames);
   
    % clear temp file
    delete(yuv_name)
    
    % Deep Regressor Head
    % Rapique has been found to generate a 3884-dimensional feature but the
    % matlab implementation does not provide a method to reduce this feature
    % vector to a rating per frame or rating per video clip. Therefore, this
    % nrff feature function does not generate feature or parameter data.
    % Implementation of a deep regressor head is left to a further effort.
    


    
   
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
    % compute NR parameters
    nr_features = varargin{1};
    fps = varargin{2};
    resolution = varargin{3};
    
    
    data(1) = mean(table2array(nr_features{1}));
    
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
