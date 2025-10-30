function nr_dataset = make_empty_dataset(dataset_name, display_rows, display_cols)
% IMPORT_NR_DATASET
%   Make a new dataset, without any files.
% SYNTAX
%   [nr_dataset] = make_empty_dataset(dataset_name, display_rows, display_cols)
% SEMANTICS
% 'dataset_name' is the name of the new dataset. This should be a short
% string (e.g., 8 characters). Specify the name in single quotes, otherwise
% the program will note run (ie. 'test_ds')
%
% 'display_rows' and 'display_cols' specify the display area on the
% monitor. That is, the image or video was up-sampled or down-sampled to
% this region during the subjective test. Media processing will include
% this resizing. If not specified, the exact image size will be used, which
% is only valid if pixel-for-pixel display was used. 
%
% The return value ('nr_dataset') has the structure of the dataset variable,
% which describes one subjective test.  
%
% See also 'import_dataset.m'

    % default categories
    % category 1 splits between originals from camera or edting, vs compressed media
    category_list{1} = categorical({'original', 'compressed', 'error'});
    category_name{1} = 'Camera vs compression vs error';

    % category 2 is train vs verify
    category_list{2} = categorical({'train', 'verify'});
    category_name{2} = 'Training vs verification';

    % category 3 is camera list.
    category_list{3} = categorical({'av1','avc','hevc','mpeg2','mpeg4','video','jpeg','png','bmp'});
    category_name{3} = 'Codec';

    % cateogry 4 is monitor resolution; choose closest resolution 
    category_list{4} = categorical({...
        'qHD', ...  % 960 x 540
        'HD', ...   % 1280 x 720 
        'HD+', ...  % 1600 x 900 
        'FHD', ...  % 1920 x 1080 and 1900 x 1200
        'QHD', ...  % 2560 x 1440
        '4K', ...   % 3840 x 2160
        '5K', ...   % 5120 x 2880
        '8K'});     % 7680 x 4320 
    category_name{4} = 'Monitor resolution'; 

    % cateogries unique to this test 
    category_list{5} = categorical({});
    category_name{5} = ''; 
    category_list{6} = categorical({});
    category_name{6} = '';
    category_list{7} = categorical({});
    category_name{7} = '';
    category_list{8} = categorical({});
    category_name{8} = '';

    %% ------------------------------------------------------------------------
    % empty media
    media.name = '';
    media.file = '';
    media.bitstream_usable = false;
    media.image_rows = display_rows;
    media.image_cols = display_cols;
    media.video_standard = 'progressive';
    media.fps = nan;
    media.start = 1;
    media.stop = 1;
    media.valid_top = nan;
    media.valid_left = nan;
    media.valid_bottom = nan;
    media.valid_right = nan;
    media.mos = nan;
    media.sos = nan;
    media.raw_mos = nan;
    media.raw_sos = nan;
    media.jnd = nan;
    media.codec = '';
    media.profile = '';
    media.dynamic_range = 'sdr';
    media.color_space = '';
    media.tv_standard = '';
    media.display_ratio = [nan nan];
    media.category1 = categorical(missing);
    media.category2 = categorical({'train'});
    media.category3 = categorical(missing);
    media.category4 = categorical(missing);
    media.category5 = categorical(missing);
    media.category6 = categorical(missing);
    media.category7 = categorical(missing);
    media.category8 = categorical(missing);
    media.miscellaneous = {};


    %% ------------------------------------------------------------------------
    % establish basic structure. Fill out detail later.
    nr_dataset.dataset_name = dataset_name;
    nr_dataset.path = ' ';
    nr_dataset.media = media;
    nr_dataset.is_mos = true;
    nr_dataset.mos_range = [1 5];
    nr_dataset.raw_mos_range = [1 5];
    nr_dataset.category_list = category_list;
    nr_dataset.category_name = category_name;
    nr_dataset.miscellaneous = {};
    nr_dataset.sujson_file = '';
    nr_dataset.version = 2.0;

end
