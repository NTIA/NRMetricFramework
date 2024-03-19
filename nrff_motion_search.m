function [data] = nrff_motion_search(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implement standard function calls to calculate motion-search data
%  using the motion-search algorithm developed by facebook research.
%  motion search is available here: 
%  https://github.com/facebookresearch/motion-search
%  
%  The motion search code must be downloaded and compiled for your operating
%  system. The resulting motion_search.exe program is called from this script
%
%  temporary files are generated and deleted to accommodate the .exe output
%  this nrff cannot be run in parallel mode
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% REQUIREMENT
%  The 'motion_search.exe' executable must be in your Documents directory,
%  sub-directory MATLAB/motion-search/
%
%  Alternatively, navigate to initialization of the "exe_path" variable in the "pixels" section.
%  Variable 'path_motion_search' must point to the executable motion_search.exe
%  Change variable 'exe_path' to point to the location of this executable. 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'motion-search';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')

    data{1} = 'picNum';
    data{2} = 'picType';
    data{3} = 'count_I';
    data{4} = 'count_P';
    data{5} = 'count_B';
    data{6} = 'error';
    data{7} = 'bits';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = 'bps';
    data{2} = 'eps';
    data{3} = 'mean_error';
    data{4} = 'Ifrac';
    data{5} = 'Pfrac';
    data{6} = 'Bfrac';
    data{7} = 'mean_countP_countI_ratio';
    data{8} = 'bps_pixels'; %look at scale, need a metric 0-1 possible normalization opportunity
    data{9} = 'max_relational_error';
    data{10} = 'mean_relational_error';
    data{11} = 'std_raw_vs_all_error';
    data{12} = 'mean_raw_vs_all_error';
    data{13} = 'max_relational_bits';
    data{14} = 'mean_relational_bits';
    data{15} = 'std_raw_vs_all_bits';
    data{16} = 'mean_raw_vs_all_bits';
    data{17} = 'max_relational_countP';
    data{18} = 'mean_relational_countP';
    data{19} = 'std_raw_vs_all_countP';
    data{20} = 'mean_raw_vs_all_countP';
    data{21} = 'mean_error_vs_mean_bits';
    data{22} = 'mean_countP_vs_mean_bits';
    data{23} = 'max_bps';
    data{24} = 'max_to_mean_bits_per_frame';
    
    

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
    [~,~,frames] = size(y);
    
    if isnan(fps) && (frames == 1)
        warning('media must be minimum of 2 frames');
        return;
    end
    
    % Convert the video into the YUV format used by motion_search.exe
    mode = 'w';
    filename = [tempname,'.yuv'];
    fid=fopen(filename,mode);
    if (fid < 0) 
        error('Could not open the file!');
    end
    for i=1:frames
        Yd = y(:,:,i)';
        fwrite(fid,Yd,'uint8');    
        Ud = cb(:,:,i)';  
        fwrite(fid,Ud,'uint8');
        Vd = cr(:,:,i)'; 
        fwrite(fid,Vd,'uint8');   
    end
    fclose(fid);
    text_file_name = join([erase(filename, 'yuv'), 'txt']);

    % Change this line to point to the motion_search executable, if it
    % is not in the recommended directory.
    exe_path = ['C:\Users\' getenv('USERNAME') '\Documents\MATLAB\motion-search\'];
    path_motion_search = [exe_path 'motion_search.exe'];
    command = join([path_motion_search, filename, "-W=1920 -H=1080", text_file_name]," ");

    % Execute motion_search
    [status,cmdout] = system(command);

    % Read the text file produced by motion_search.exe
    try
        motion_search_data = readtable(text_file_name);
    catch
        warning('motion search output file has not been found');
        pause(5)
        [status,cmdout] = system(command);
        pause(1)
        motion_search_data = readtable(text_file_name);
      
    end

    % Copy this data into the seven features
    data{1} = motion_search_data(:,1);
    data{2} = motion_search_data(:,2);
    data{3} = motion_search_data(:,3);
    data{4} = motion_search_data(:,4);
    data{5} = motion_search_data(:,5);
    data{6} = motion_search_data(:,6);
    data{7} = motion_search_data(:,7);

    % delete temporary files
    delete (filename);
    delete (text_file_name);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
    % compute NR parameters
    
    nr_features = varargin{1};
    fps = varargin{2};
    resolution = varargin{3};

    Icount = table2array(nr_features{3});  
    Pcount = table2array(nr_features{4});  
    Bcount = table2array(nr_features{5});  

    raw_error = table2array(nr_features{6});  
    raw_bits = table2array(nr_features{7});

    % compute bits per second
    data(1) = sum(raw_bits) / fps;
    
    % Compute bits per second and average error rate
    data(2) = sum(raw_error) / fps;
    data(3) = mean(raw_error);

    % Compute ratio of I blocks, P blocks, and B blocks in the overall
    % video stream
    data(4) = mean(Icount) / (mean(Pcount) + mean(Icount) + mean(Bcount));
    data(5) = mean(Pcount) / (mean(Pcount) + mean(Icount) + mean(Bcount));
    data(6) = mean(Bcount) / (mean(Pcount) + mean(Icount) + mean(Bcount));
    
    % count P to I ratio
    countP_vs_countI = Pcount ./ Icount;
    data(7) = mean(countP_vs_countI);
    
    % bps over total pixels
    total_pixels = resolution(1)*resolution(2);
    bps_pixels = sum(raw_bits/total_pixels) / fps;

    data(8) = bps_pixels;

    % relation to macro characteristics of signal's error
    % these statistics (mean and std) are calculated for the VCRDCI
    % dataset, to enable normalization
    std_error = 1.540849354651965e+06;
    mean_error = 6.601350516431925e+05;

    dist_mean_error = raw_error - mean_error;

    rel_to_std_error = dist_mean_error ./ std_error;

    max_relational_error = max(abs(rel_to_std_error));

    mean_relational_error = mean(rel_to_std_error);
    
    data(9) = max_relational_error;
    data(10) = mean_relational_error;
    
    std_raw_vs_all_error = std(raw_error)/std_error;
    mean_raw_vs_all_error = mean(raw_error)/mean_error;
    data(11) = std_raw_vs_all_error;
    data(12) = mean_raw_vs_all_error;

    % bits
    % these statistics (mean and std) are calculated for the VCRDCI
    % dataset, to enable normalization
    std_bits = 3.813095067689049e+04;
    mean_bits = 5.064340802390098e+04;

    dist_mean_bits = raw_bits - mean_bits;

    rel_to_std_bits = dist_mean_bits ./ std_bits;

    max_relational_bits = max(abs(rel_to_std_bits));

    mean_relational_bits = mean(rel_to_std_bits);
    
    data(13) = max_relational_bits;
    data(14) = mean_relational_bits;
    
    std_raw_vs_all_bits = std(raw_bits)/std_bits;
    mean_raw_vs_all_bits = mean(raw_bits)/mean_bits;
    data(15) = std_raw_vs_all_bits;
    data(16) = mean_raw_vs_all_bits;

    % p count
    % these statistics (mean and std) are calculated for the VCRDCI
    % dataset, to enable normalization

    std_countP = 4.871984720291511e+02;
    mean_countP = 3.585241143832693e+02;

    dist_mean_countP = Pcount - mean_countP;

    rel_to_std_countP = dist_mean_countP ./ std_countP;

    max_relational_countP = max(abs(rel_to_std_countP));

    mean_relational_countP = mean(rel_to_std_countP);
    
    data(17) = max_relational_countP;
    data(18) = mean_relational_countP;
    
    std_raw_vs_all_countP = std(Pcount)/std_countP;
    mean_raw_vs_all_countP = mean(Pcount)/mean_countP;
    data(19) = std_raw_vs_all_countP;
    data(20) = mean_raw_vs_all_countP;
    
    % ratio of bits to error

    data(21) = mean(raw_error) / mean(raw_bits);
    data(22) = mean(Pcount) / mean(raw_bits);

    % max figures
    max_bps = max(raw_bits / fps);
    data(23) = max_bps;
    
    % max to mean ratios
    max_bits = max(raw_bits);
    bits_max_to_mean = max_bits / mean_bits;
    data(24) = bits_max_to_mean;

    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
