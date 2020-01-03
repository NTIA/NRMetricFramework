function status = check_dataset(nr_dataset)
% CHECK_DATASET
%   Check a dataset structure for errors.
% SYNTAX
%   [status] = check_dataset(nr_dataset);
% SEMANTICS
%   Take as input a dataset, 'nr_dataset', formatted as specified by
%   import_dataset.m and export_dataset.m. Check the structure for errors.
%   Print problems to the screen. 
%
%   Return status = true if no errors are found.
%   Return status = false if problems are found.



if isfield(nr_dataset,'version') && nr_dataset.version == 1    
    status = check_dataset_ver1 (nr_dataset);
else
    fprintf('Error: unknown dataset structure version detected; cannot check dataset variable validity.\n'); 
    status = false;
end

return;


function status = check_dataset_ver1 (nr_dataset)

status = true;

% check top level
fields = fieldnames(nr_dataset);

if ~strcmp(fields{1},'test') || ~strcmp(fields{2},'path') || ...
        ~strcmp(fields{3},'media') || ~strcmp(fields{4},'is_mos') || ...
        ~strcmp(fields{5},'mos_range') || ~strcmp(fields{6},'raw_mos_range') || ...
        ~strcmp(fields{7},'category_list') || ~strcmp(fields{8},'category_name') || ...
        ~strcmp(fields{9},'miscellaneous') || ~strcmp(fields{10},'sujson_file') || ...
        ~strcmp(fields{11},'version')
    fprintf('Error: Dataset structure fields in wrong order or missing\n\n');
    status = false;
end

% make sure there is a valid test name
if ~ischar(nr_dataset.test) || length(nr_dataset.test) < 1 
    fprintf('Error: field "test" must be a character array; 3 to 10 character length recommended\n\n');
    status = false;
end

% check MOSs
if nr_dataset.mos_range(1) ~= 1 || nr_dataset.mos_range(2) ~= 5
    fprintf('Warning: Non-standard MOS range specified [%g..%g]\n', nr_dataset.mos_range(1), nr_dataset.mos_range(2));
    fprintf('         Some plotting and analysis functions may not operate correctly\n'); 
    fprintf('         We recommend linearly scaling MOSs to the [1..5] range\n');
    fprintf('         Note: use raw_mos for the unscaled MOSs\n\n');
end


if min([nr_dataset.media.mos]) < nr_dataset.mos_range(1) || max([nr_dataset.media.mos]) > nr_dataset.mos_range(2)
    fprintf('Warning: MOSs detected outside the specified range of [%g..%g]\n', nr_dataset.mos_range(1), nr_dataset.mos_range(2));
    fprintf('         Actual range is [%4.2f..%4.2f]\n\n', min([nr_dataset.media.mos]), max([nr_dataset.media.mos]));
end


% check path, ensure valid
is_folder = true;
if ~exist(nr_dataset.path,'dir')
    fprintf('Error: Media folder does not exist: %s\n', nr_dataset.path);
    status = false;
    is_folder = false;
end
tmp = nr_dataset.path;
tmp = tmp(length(tmp));
if tmp ~= '\' && tmp ~= '/'
    fprintf('Error: Media path must end with a forward or backward slash\n');
    status = false;
    is_folder = false;
end

% check that all files exist
if is_folder
    is_first = true;
    for cnt=1:length(nr_dataset.media)
        if ~exist([nr_dataset.path nr_dataset.media(cnt).file], 'file')
            if is_first
                is_first = false;
                status = false;
                fprintf('Error: the following media files not found in %s:\n', nr_dataset.path);
            end
            fprintf('- media %d (%s)\n', cnt, nr_dataset.media(cnt).file); 
        end
    end
    if ~is_first
        fprintf('\n');
    end
end

return;
