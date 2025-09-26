function [data] = nrff_pyiqa(mode, varargin)
% No-Reference Feature Function (NRFF)
%  Implements function calls to calculate feature data from a metric in 
%  the pyiqa toolbox developed by Chaofeng Chen and Jiadi Mo.
%  pyiqa is available here: 
%  https://pypi.org/project/pyiqa/
%  and documentation below:
%  https://iqa-pytorch.readthedocs.io/en/latest/
%  
%  The pyiqa code was downloaded through pypi, and a virtual environment was created
%  to run this package in an isolated workspace. The nrff function creates a 
%  system call to execute the pyiqa command line within the virtual environment. 
%
%  temporary files are generated and deleted to accommodate pyiqa need for a single image as the input.
%  Consequently, each frame must be saved as a temporary image to be input
%  into pyiqa.
%  This nrff cannot be run in parallel mode.
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% REQUIREMENT
%  The toolbox is installed in a virtual environment. The 
%  miniforge python package was used to create an environment in which the pypi
%  implementation of pyiqa could be installed. Pyiqa can be run within a python scripts or called from the
%  command line directly. nrff_pyiqa.m saves temporary images to be analyzed in the temp_file_path.
%  Pyiqa generates a command line output which the nrff function reads, parses the output, and formats 
%  the metric data into the nrff_function format. This nrff_function is not currently designed to save 
%  each feature data, and was only used to evaluate the viability of
%  the toolbox. 
%  The virtual environment file path and the temporary csv
%  file path are specified below as an example, and must be changed to the system environment 
%  running this feature function. 

% miniforge python virtual environment with pyiqa installed through pip 
% virtualenv_path = "C:\Users\<User ID>\AppData\Local\miniforge3\envs\pyiqa\Scripts\pyiqa.exe";
virtualenv_path = "C:\Users\rgrosso.labnet\AppData\Local\miniforge3\envs\pyiqa\Scripts\pyiqa.exe";

% temporary path for converted image
% temp_file_path = "C:\Users\<User ID>\Documents\python_scripts\pyiqa";
temp_file_path = "C:\Users\rgrosso.labnet\Documents\python_scripts\pyiqa";

% choose a feature to run, copy and paste from list of features below
metric_under_test = 'maniqa';


 % did not run
    %'clipscore'
    %'fid'
    %'inception_score'
    %'qalign_4bit' no GPU
    %'qalign_8bit' no GPU
    %'topiq_nr-face' no face detected


 % full reference metrics
    %'ahiq'
    %'ckdn'
    %'cw_ssim'
    %'dists'
    %'fsim'
    %'gmsd'
    %'lpips'
    %'lpips+'
    %'lpips-vgg'
    %'mad'
    %'ms_ssim'
    %'msswd'
    %'nlpd'
    %'pieapp'
    %'psnr'
    %'psnry'
    %'ssim'
    %'ssimc'
    %'stlpips'
    %'stlpips-vgg'
    %'topiq_fr'
    %'topiq_fr-pipal'
    %'vif'
    %'vsi'
    %'wadiqam_fr'


 % O(n) nrff_blur 5.15s for 10 images
 % no reference metrics
    % 'arniqa'                  158.837919
    % 'arniqa-clive'            137.536656
    % 'arniqa-csiq'             128.648726
    % 'arniqa-flive'            124.238919
    % 'arniqa-kadid'
    % 'arniqa-live'
    % 'arniqa-spaq'
    % 'arniqa-tid'
    % 'brisque'                 72.8s
    % 'brisque_matlab'
    % 'clipiqa'
    % 'clipiqa+'                157.873657
    % 'clipiqa+_rn50_512'
    % 'clipiqa+_vitL14_512'
    % 'cnniqa'
    % 'dbcnn'
    % 'entropy'                 95.337146
    % 'hyperiqa'
    % 'ilniqe'
    % 'laion_aes'
    % 'liqe'                    116.533024
    % 'liqe_mix'
    % 'maniqa'                  289.359419
    % 'maniqa-kadid'
    % 'maniqa-pipal'
    % 'musiq'                   187.225388
    % 'musiq-ava'
    % 'musiq-paq2piq'
    % 'musiq-spaq'
    % 'nima'                    137.531044
    % 'nima-koniq'
    % 'nima-spaq'
    % 'nima-vgg16-ava'
    % 'niqe'
    % 'niqe_matlab'             143.302182
    % 'nrqm'
    % 'paq2piq'                 84.411501
    % 'pi'
    % 'piqe'                    84.410260
    % 'qalign'
    % 'topiq_iaa'
    % 'topiq_iaa_res50'
    % 'topiq_nr'                170.380894
    % 'topiq_nr-flive'
    % 'topiq_nr-spaq'
    % 'tres'
    % 'tres-flive'
    % 'unique'
    % 'uranker'
    % 'wadiqam_nr'              93.580966

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(mode, 'group')
    data = 'pyiqa';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(mode, 'feature_names')
    
   data{1} = metric_under_test;
   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
elseif strcmp(mode, 'parameter_names')

    data{1} = strcat(metric_under_test, '_mean');
    
    
    

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

    file_path = varargin{5};
    file_name = varargin{6};

    
    %iterate through frames
    
    metric_value = [];

    for Y=1:frames
        
        % format YUV data into ycbcr
        ycbcr = y(:,:,Y);
        ycbcr(:,:,2)=cb(:,:,Y);
        ycbcr(:,:,3)=cr(:,:,Y);
    
        % convert ycbcr to rgb
        rgb = ycbcr2rgb_double(ycbcr,'128');
    

    
        % create temp file folder
        file_path = varargin{5};
        filename = varargin{6};

        if ~exist(temp_file_path), mkdir(temp_file_path); end
    
        temp_img_path = fullfile(temp_file_path,'img.png');
        
        if exist(temp_img_path), delete(temp_img_path); end
        
        % write rgb image to temp file
        imwrite(uint8(rgb),temp_img_path);
        

        
        % format system command
        command = join(["cd" temp_file_path, "&&", virtualenv_path, metric_under_test,'--target', temp_img_path]," ");

        % execute pyiqa
        [status,cmdout] = system(command);

        % parse response 
        k = strfind(cmdout,"{");
        json_start = k(1);

        if strcmp(metric_under_test, 'maniqa')
            json_start = k(2);
        end

        json_string = replace(cmdout(json_start:end),"'",'"');

        v = jsondecode(json_string);

        json_metric_under_test = replace(replace(metric_under_test,'-','_'), '+','_');

        metric_value(Y) = v.(json_metric_under_test).("mean");

    
        

        % delete temporary files
        if isfile(temp_file_path)
           delete (temp_file_path);
        end
    
    end
    % Copy this data into the feature format
    data{1} = metric_value;

    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(mode, 'pars')
    
    % compute NR parameters
    
    nr_features = varargin{1};
    fps = varargin{2};
    resolution = varargin{3};
    
    % Simple mean ignoring nan
    data(1) = nanmean(nr_features{1});
    
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
