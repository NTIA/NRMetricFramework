function [data] = nrff_agh_vqis(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard function calls to calculate agh-vqis data
%  using the agh-vqis algorithm developed by the AGH Video Quality Team.
%  agh-vqis is available here: 
%  https://qoe.agh.edu.pl/indicators/
%  and also below pypi:
%  https://pypi.org/project/agh-vqis/
%  
%  The agh-vqis code was downloaded through pypi, and a virtual environment was created
%  to run this package in an isolated workspace. The nrff function creates a 
%  system call to execute an agh-vqis script within the virtual environment. 
%
%  temporary files are generated and deleted to accommodate the csv output.
%  This nrff cannot be run in parallel mode.
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% REQUIREMENT
%  The agh-vqis package must be installed in a virtual environment. The 
%  virtualenv python package was used to create an environment in which the pypi
%  implementation of agh-vqis could be run. Agh-vqis generates csv files which are 
%  stored in a temporary file path. The csv files are deleted after being processed by 
%  the nrff function. The virtual environment file path and the temporary csv
%  file path are specified below as an example, and must be changed to the system environment 
%  running this feature function. 


virtualenv_path = "C:\Users\<user.account>\.virtualenvs\agh_vqis-NBMkG_ig\Scripts\python.exe";
temp_file_path = "C:\Users\<user.account>>\Documents\python_scripts\agh_vqis";

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'agh_vqis';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')

    data{1} = 'Blockiness';
    data{2} = 'SA';
    data{3} = 'Letterbox';
    data{4} = 'Pillarbox';
    data{5} = 'Blockloss';
    data{6} = 'Blur';
    data{7} = 'TA';
    data{8} = 'Blackout';
    data{9} = 'Freezing';
    data{10} = 'Exposure';
    data{11} = 'Contrast';
    data{12} = 'Interlace';
    data{13} = 'Noise';
    data{14} = 'Slice';
    data{15} = 'Flickering';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'Blockiness_mean';
    data{2} = 'SA_mean';
    data{3} = 'Letterbox_mean';
    data{4} = 'Pillarbox_mean';
    data{5} = 'Blockloss_mean';
    data{6} = 'Blur_mean';
    data{7} = 'TA_mean';
    data{8} = 'Blackout_mean';
    data{9} = 'Freezing_mean';
    data{10} = 'Exposure_mean';
    data{11} = 'Contrast_mean';
    data{12} = 'Interlace_mean';
    data{13} = 'Noise_mean';
    data{14} = 'Slice_mean';
    data{15} = 'Flickering_mean';
    
    

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
    [~,~,frames] = size(y);
    
    if isnan(fps) && (frames == 1)
        warning('media must be minimum of 2 frames');
        return;
    end
   

    

    % forumlate csv file name
    if contains(filename, 'mp4')
        csv_file_name = fullfile(temp_file_path,join(['VQIs_for_',join([erase(filename, 'mp4'), 'csv'])]));
    elseif contains(filename, 'avi')
        csv_file_name = fullfile(temp_file_path,join(['VQIs_for_',join([erase(filename, 'avi'), 'csv'])]));
    end

    %handle an unnaceptable character
    temp_file_flag = false;
    if contains(filename,'&')
        temp_file_name = erase(filename, '&');
        copyfile(fullfile(file_path,filename),fullfile(temp_file_path,temp_file_name));
        file_path = temp_file_path;
        filename = temp_file_name;
        temp_file_flag = true;
        csv_file_name = fullfile(temp_file_path,join(['VQIs_for_',join([erase(filename, 'avi'), 'csv'])]));
    end
        

    if isfile(csv_file_name)
        delete (csv_file_name);
    end
    
    
    command = join(["cd" temp_file_path, "&&", virtualenv_path, "-m agh_vqis", fullfile(file_path,filename)]," ");

    % Execute motion_search
    [status,cmdout] = system(command);

    try
        pause(1)
        agh_vqis_data = readtable(csv_file_name,ReadVariableNames=false);
    catch
        warning('agh_vqis output file has not been found');
        pause(5)
        [status,cmdout] = system(command);
        pause(1)
        agh_vqis_data = readtable(csv_file_name,ReadVariableNames=false);
      
    end 
    if temp_file_flag == true
        delete(fullfile(file_path,filename));
    end


    % Copy this data into the features
    data{1} = agh_vqis_data(:,2);
    data{2} = agh_vqis_data(:,3);
    data{3} = agh_vqis_data(:,4);
    data{4} = agh_vqis_data(:,5);
    data{5} = agh_vqis_data(:,6);
    data{6} = agh_vqis_data(:,7);
    data{7} = agh_vqis_data(:,8);
    data{8} = agh_vqis_data(:,9);
    data{9} = agh_vqis_data(:,10);
    data{10} = agh_vqis_data(:,11);
    data{11} = agh_vqis_data(:,12);
    data{12} = agh_vqis_data(:,13);
    data{13} = agh_vqis_data(:,14);
    data{14} = agh_vqis_data(:,15);
    data{15} = agh_vqis_data(:,16);

    % delete temporary files
    if isfile(csv_file_name)
        delete (csv_file_name);
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
    % compute NR parameters
    
    nr_features = varargin{1};
    fps = varargin{2};
    resolution = varargin{3};
    
    
    data(1) = mean(table2array(nr_features{1}));
    data(2) = mean(table2array(nr_features{2}));
    data(3) = mean(table2array(nr_features{3}));
    data(4) = mean(table2array(nr_features{4}));
    data(5) = mean(table2array(nr_features{5}));
    data(6) = mean(table2array(nr_features{6}));
    data(7) = mean(table2array(nr_features{7}));
    data(8) = mean(table2array(nr_features{8}));
    data(9) = mean(table2array(nr_features{9}));
    data(10) = mean(table2array(nr_features{10}));
    data(11) = mean(table2array(nr_features{11}));
    data(12) = mean(table2array(nr_features{12}));
    nr_array = table2array(nr_features{13});
    nr_array = nr_array(~isnan(nr_array)); % remove NaNs
    data(13) = mean(nr_array);
    data(14) = mean(table2array(nr_features{14}));
    data(15) = mean(table2array(nr_features{15}));
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
