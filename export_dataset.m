function export_dataset(nr_dataset, filename)
% EXPORT_DATASET
%   Export dataset into an XLS file, to be reviewed and checked
% SYNTAX
%   export_dataset(nr_dataset, filename)
%       -nr_dataset is the output of import_dataset.m
%       -filename is the location (absolute path) to the file you want to
%       write the dataset to. If the file doesn't exist, the file will be
%       created. If an extension is not specified, the default .xls
%       extension will be used. 
% SEMANTICS
%   Export dataset 'nr_dataset' to MS-Excel file 'filename'
%   Intended to help the user easily review and understand the dataset categories
%   If 'nr_dataset' is empty (i.e., []), export an empty dataset.
%
%   See also import_dataset.
%   See Matlab Documentation for xlswrite for more information.

    if ischar(filename)
        filename = string(filename);
    end

    % check fields
    if ~isa(filename, 'string') || filename == ""
        fprintf("  Invalid Filename ""%s"", Must Be a Non-Empty String\n", string(filename))
        return
    end
    if ~endsWith(filename, ".xls") && ~endsWith(filename, ".xlsx")
        fprintf("  Invalid Filename ""%s"" Extension, Must be "".xls"" or "".xlsx""\n", string(filename))
        return
    end

    % remove file if present
    if exist(filename, 'file') == 2
        delete(filename)
    end

    % if nr_dataset is empty, export an empty dataset
    if isempty(nr_dataset)
        nr_dataset = import_dataset(nan);
    end

    % turn add sheet warning off
    warning('off', 'MATLAB:xlswrite:AddSheet');

    % write to xls file for checks
    
    % -----------------------------------------------------------------
    % write media files and media names
    xlsdata{1,1} = 'file';
    xlsdata{1,2} = 'name';
    for cnt=1:8
        xlsdata{1,2+cnt} = sprintf('Category%d', cnt);
    end
    
    % write category choices for each media
    for cnt=1:length(nr_dataset.media)
        xlsdata{cnt+1,1} = nr_dataset.media(cnt).file;
        xlsdata{cnt+1,2} = nr_dataset.media(cnt).name;
        
        if ~ismissing(nr_dataset.media(cnt).category1)
            xlsdata{cnt+1,3} = char(nr_dataset.media(cnt).category1);
        end
        if ~ismissing(nr_dataset.media(cnt).category2)
            xlsdata{cnt+1,4} = char(nr_dataset.media(cnt).category2);
        end
        if ~ismissing(nr_dataset.media(cnt).category3)
            xlsdata{cnt+1,5} = char(nr_dataset.media(cnt).category3);
        end
        if ~ismissing(nr_dataset.media(cnt).category4)
            xlsdata{cnt+1,6} = char(nr_dataset.media(cnt).category4);
        end
        if ~ismissing(nr_dataset.media(cnt).category5)
            xlsdata{cnt+1,7} = char(nr_dataset.media(cnt).category5);
        end
        if ~ismissing(nr_dataset.media(cnt).category6)
            xlsdata{cnt+1,8} = char(nr_dataset.media(cnt).category6);
        end
        if ~ismissing(nr_dataset.media(cnt).category7)
            xlsdata{cnt+1,9} = char(nr_dataset.media(cnt).category7);
        end
        if ~ismissing(nr_dataset.media(cnt).category8)
            xlsdata{cnt+1,10} = char(nr_dataset.media(cnt).category8);
        end
    end
    
    
    xlswrite(filename, xlsdata, 'Category','A1');
    
    % -----------------------------------------------------------------
    % write category summary
    clear xlsdata;
    
    for cnt=1:8
        xlsdata{1,cnt} = sprintf('Category%d', cnt);
        for cnt2=1:length( nr_dataset.category_list{1, cnt})
            if ~ismissing(nr_dataset.category_list{1, cnt}(cnt2))
                value = string(nr_dataset.category_list{1,cnt}(cnt2));
                xlsdata{1+cnt2, cnt} = value{1}; 
            end
        end
    end
    

    
    xlswrite(filename, xlsdata, 'Category_list', 'A1');
    % -----------------------------------------------------------------
    % write category name
    clear xlsdata;
    
    for cnt=1:8
        xlsdata{cnt,1} = sprintf('Category%d', cnt);
        value = string(nr_dataset.category_name{1, cnt});
        if ~ismissing(value)
            xlsdata{cnt,2} = value{1};
        end

    end
    xlswrite(filename, xlsdata, 'Category_name', 'A1');


    % -----------------------------------------------------------------
    % write MOSs and other subjective data
    clear xlsdata;

    for cnt=1:length(nr_dataset.media)
        xlsdata{cnt+1,1} = nr_dataset.media(cnt).file;
        xlsdata{cnt+1,2} = nr_dataset.media(cnt).name;
        xlsdata{cnt+1,3} = nr_dataset.media(cnt).mos;
        xlsdata{cnt+1,4} = nr_dataset.media(cnt).sos;
        xlsdata{cnt+1,5} = nr_dataset.media(cnt).raw_mos;
        xlsdata{cnt+1,6} = nr_dataset.media(cnt).raw_sos;
        xlsdata{cnt+1,7} = nr_dataset.media(cnt).jnd;
    end
    xlsdata{1,1} = 'file';
    xlsdata{1,2} = 'name';
    xlsdata{1,3} = 'mos';
    xlsdata{1,4} = 'sos';
    xlsdata{1,5} = 'raw_mos';
    xlsdata{1,6} = 'raw_sos';
    xlsdata{1,7} = 'jnd';

    xlswrite(filename, xlsdata, 'MOS', 'A1');

    % -----------------------------------------------------------------
    % write information on where to read the image or video
    clear xlsdata;

    % write media files and media names
    for cnt=1:8
        xlsdata{1,2+cnt} = cnt;
    end
    for cnt=1:length(nr_dataset.media)
        xlsdata{cnt+1,1} = nr_dataset.media(cnt).file;
        xlsdata{cnt+1,2} = nr_dataset.media(cnt).name;
        xlsdata{cnt+1,3} = nr_dataset.media(cnt).bitstream_usable;
        xlsdata{cnt+1,4} = nr_dataset.media(cnt).image_rows;
        xlsdata{cnt+1,5} = nr_dataset.media(cnt).image_cols;
        xlsdata{cnt+1,6} = nr_dataset.media(cnt).video_standard;
        xlsdata{cnt+1,7} = nr_dataset.media(cnt).fps;
        xlsdata{cnt+1,8} = nr_dataset.media(cnt).start;
        xlsdata{cnt+1,9} = nr_dataset.media(cnt).stop;
        xlsdata{cnt+1,10} = nr_dataset.media(cnt).valid_top;
        xlsdata{cnt+1,11} = nr_dataset.media(cnt).valid_left;
        xlsdata{cnt+1,12} = nr_dataset.media(cnt).valid_bottom;
        xlsdata{cnt+1,13} = nr_dataset.media(cnt).valid_right;
    end
    xlsdata{1,1} = 'file';
    xlsdata{1,2} = 'name';
    xlsdata{1,3} = 'bitstream_usable';
    xlsdata{1,4} = 'image_rows';
    xlsdata{1,5} = 'image_cols';
    xlsdata{1,6} = 'video_standard';
    xlsdata{1,7} = 'fps';
    xlsdata{1,8} = 'start';
    xlsdata{1,9} = 'stop';
    xlsdata{1,10} = 'valid_top';
    xlsdata{1,11} = 'valid_left';
    xlsdata{1,12} = 'valid_bottom';
    xlsdata{1,13} = 'valid_right';

    xlswrite(filename, xlsdata, 'Read', 'A1');

    % -----------------------------------------------------------------
    % write format info
    clear xlsdata;

    % write media files and media names
    for cnt=1:8
        xlsdata{1,2+cnt} = cnt;
    end
    for cnt=1:length(nr_dataset.media)
        xlsdata{cnt+1,1} = nr_dataset.media(cnt).file;
        xlsdata{cnt+1,2} = nr_dataset.media(cnt).name;
        xlsdata{cnt+1,3} = nr_dataset.media(cnt).codec;
        xlsdata{cnt+1,4} = nr_dataset.media(cnt).profile;
        xlsdata{cnt+1,5} = nr_dataset.media(cnt).dynamic_range;
        xlsdata{cnt+1,6} = nr_dataset.media(cnt).color_space;
        xlsdata{cnt+1,7} = nr_dataset.media(cnt).tv_standard;
        if length(nr_dataset.media(cnt).display_ratio) == 2
            xlsdata{cnt+1,8} = nr_dataset.media(cnt).display_ratio(1);
            xlsdata{cnt+1,9} = nr_dataset.media(cnt).display_ratio(2);
        end       
        for loop=1:length(nr_dataset.media(cnt).miscellaneous)
            xlsdata{cnt+1,9+loop} = nr_dataset.media(cnt).miscellaneous{loop};
        end
    end
    xlsdata{1,1} = 'file';
    xlsdata{1,2} = 'name';
    xlsdata{1,3} = 'codec';
    xlsdata{1,4} = 'profile';
    xlsdata{1,5} = 'dynamic_range';
    xlsdata{1,6} = 'color_space';
    xlsdata{1,7} = 'tv_standard';
    xlsdata{1,8} = 'display_ratio_horiz';
    xlsdata{1,9} = 'display_ratio_vert';

    xlsdata{1,10} = 'miscellaneous';
    xlswrite(filename, xlsdata, 'Format', 'A1');

    
    % -----------------------------------------------------------------
    % write high level summary of whole test
    
    clear xlsdata;
    xlsdata{1,1} = 'test';
    xlsdata{1,2} = nr_dataset.test;
    xlsdata{2,1} = 'path';
    xlsdata{2,2} = nr_dataset.path;
    xlsdata{3,1} = 'is_mos';
    xlsdata{3,2} = nr_dataset.is_mos;
    xlsdata{4,1} = 'mos range';
    xlsdata{4,2} = nr_dataset.mos_range(1);
    xlsdata{4,3} = nr_dataset.mos_range(2);
    xlsdata{5,1} = 'raw_mos range';
    xlsdata{5,2} = nr_dataset.raw_mos_range(1);
    xlsdata{5,3} = nr_dataset.raw_mos_range(2);
    xlsdata{6,1} = 'miscellaneous';
    for cnt=1:length(nr_dataset.miscellaneous)
        xlsdata{6,1+cnt} = nr_dataset.miscellaneous{cnt};
    end
    xlsdata{7,1} = 'sujson_file';
    xlsdata{7,2} = nr_dataset.sujson_file;
    xlsdata{8,1} = 'version';
    xlsdata{8,2} = nr_dataset.version;
    
    xlswrite(filename, xlsdata, 'Dataset', 'A1');
    
    % turn add sheet warning on
    warning('on', 'MATLAB:xlswrite:AddSheet');    
    
    % remove blank excel "Sheet1"
    objExcel = actxserver('Excel.Application');
    objExcel.Workbooks.Open(which(filename));
    objExcel.ActiveWorkbook.Worksheets.Item(['Sheet1']).Delete;

    objExcel.ActiveWorkbook.Save;
    objExcel.ActiveWorkbook.Close;
    objExcel.Quit;
    objExcel.delete;
end
