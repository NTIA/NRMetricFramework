function [nr_dataset] = run_sawatch(input_file, output_file, data_dir, parallel_mode, dataset_name, display_rows, display_cols)
% RUN_SAWATCH
%    Run the NR metric Sawatch on a list of files. Write metric values to a file.
% SYNTAX
%    [nr_dataset] = run_sawatch(input_file, output_file, data_dir)
%    [nr_dataset] = run_sawatch(input_file, output_file, data_dir, parallel_mode, dataset_name, display_rows, display_cols)
% SEMANTICS
%    Read the list of files in `input_file`, one file per line. Can include path names. 
%    Write to `output_file`, one file per line, the file name (no path), Sawatch metric value, and parameter 
%    values. 
%    `data_dir` will be used to hold intermediate files. 
%
%    Optional input parameters (dataset_name, display_rows, display_cols) used to initiate returned variable 
%    `nr_dataset'. By default, dataset_name = `dataset`, display_rows = 1080, display_cols = 1920, and parallel
%    mode = 'none'.
%
%   parallel_model = 
%       'none'      Linear calculation. Parallel processing toolbox avoided.
%       'stimuli'   Parallel processing on the stimuli level. 
%       'tslice'    Divide each stimuli into segments for parallel processing  
%                   Note: tslice mode automatically disabled for images 
%                   (presented as 1 fps sequences), due to inefficiencies. 
%       'all'       Do parallel processing on both the stimuli and tslice level. 
%
%                   (Note: 'all' and 'stimuli' mode cannot save progress
%                   calculating NRpars. Only features can be saved against computer crash.)
%

if nargin == 3
    parallel_mode = 'none';
    dataset_name = 'dataset';
    display_rows = 1080;
    display_cols = 1920;
elseif nargin == 7
    % no error checking
else
    error('must have either 2 or 5 input arguments');
end

% Read list of files
input_data = readtable(input_file, 'TextType','string', 'Delimiter', ',', ...
    'ReadVariableNames', false);

% Create empty dataset variable
empty_dataset = make_empty_dataset(dataset_name, display_rows, display_cols);
empty_media = empty_dataset.media(1);

% Initialize to no files
num_dirs = 0;    % number of directories in the list of input files
num_files = [];  % number of media files in each directory, currently none

% Examine each input file in turn
for cntF = 1:height(input_data)
    [path, name, ext] = fileparts(input_data{cntF,1});
    
    % find if any dataset has this file's directory
    found = false;
    for cntD = 1:num_dirs
        if strcmp(nr_dataset{cntD}.path,  [ path{1} '\' ])
            found = true;
        end
    end
    
    % if not found, initialize new dataset
    if ~found
        num_dirs = num_dirs + 1;
        cntD = num_dirs;
        nr_dataset{cntD} = empty_dataset;
        nr_dataset{cntD}.path = [ path{1} '\' ];
        num_files{cntD} = 0;
    end

    % record this file's info
    num_files{cntD} = num_files{cntD} + 1;
    media_num = num_files{cntD};
    nr_dataset{cntD}.media(media_num) = empty_media;
    nr_dataset{cntD}.media(media_num).name = char(name);
    nr_dataset{cntD}.media(media_num).file = char([name{1} ext{1}]);

    % initialize fps, length, display_ratio, valid_top, ...
    % is this an uncompressed AVI file?
    if ~strcmp(ext{1},'.avi')
        error('Function run_sawatch.m currently only works for AVI files');
    end

    % Read AVI file header info and first frame
    info = read_avi('info', char(input_data{cntF,1}));
    
    % record information from AVI file header
    nr_dataset{cntD}.media(media_num).start = 1;
    nr_dataset{cntD}.media(media_num).stop = info.NumFrames;
    nr_dataset{cntD}.media(media_num).fps = info.FramesPerSecond;
            
    % initialize valid region
    nr_dataset{cntD}.media(media_num).valid_top = 1;
    nr_dataset{cntD}.media(media_num).valid_left = 1;
    nr_dataset{cntD}.media(media_num).valid_bottom = display_rows;
    nr_dataset{cntD}.media(media_num).valid_right = display_cols;

end

% check files and dataset vars
for cntD = 1:num_dirs
    status = check_dataset(nr_dataset{cntD});
    if ~status
        error('critical problem with files or structure of input file');
    end
end

% calculate metric
for cntD = 1:num_dirs
    calculate_NRpars(nr_dataset{cntD}, data_dir, parallel_mode, @nrff_blur);
    calculate_NRpars(nr_dataset{cntD}, data_dir, parallel_mode, @nrff_auto_enhancement);
    calculate_NRpars(nr_dataset{cntD}, data_dir, parallel_mode, @nrff_fine_detail);
    calculate_NRpars(nr_dataset{cntD}, data_dir, parallel_mode, @nrff_peculiar_color);
    calculate_NRpars(nr_dataset{cntD}, data_dir, parallel_mode, @nrff_blockiness);
    calculate_NRpars(nr_dataset{cntD}, data_dir, parallel_mode, @nrff_panIPS);
    calculate_NRpars(nr_dataset{cntD}, data_dir, parallel_mode, @nrff_dipIQ);
    
    calculate_NRpars(nr_dataset{cntD}, data_dir, parallel_mode, @metric_sawatch);

    % output results
    Mdata = export_NRpars(nr_dataset{cntD}, data_dir, @metric_sawatch, []);
    if cntD == 1
        all_Mdata = Mdata;
    else
        combinedTable = vertcat(all_Mdata, Mdata);
    end
end

% write results: file name, estimated MOS, then NR RCA parameters.
write_Mdata = all_Mdata;
write_Mdata = removevars(write_Mdata,{'mos','raw_mos'});
write_Mdata = movevars(write_Mdata,"Sawatch_version_4",'After',"media"); 
writetable(write_Mdata, output_file, 'Delimiter','\t');
