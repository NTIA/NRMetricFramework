% The Document Image Quality Assessment Datasets (DIQA) are available from 
% https://lampsrv02.umiacs.umd.edu/projdb/project.php?id=73
% DIQA contains photographs of documents. Instead of subjective ratings, 
% quality is assessed by the success rate of an optical character reader
% (OCR). The DIQA images are distributed in multiple sub-directories, and
% some of the names are not unique. 
%
% This script copies the images from the two original directories
% (input_diqa1 and input_diqa2) into a destination directory (output_diqa).
% File names are prefixed with the dataset (DIQA) and information contained
% in the distribution subdirectories.
%


% This script renames the DIQA dataset images with unique names
% and organizes the objective data. 

input_diqa1 = '\\itsvideo\Gold\subjective test editing\DIQA\DIQA_Release_1.0_Part1\';
input_diqa2 = '\\itsvideo\Gold\subjective test editing\DIQA\DIQA_Release_1.0_Part2\';

output_diqa = '\\itsvideo\Gold\All_Video_Tests\jpeg__DIQA\';

% Load all three sets of OCR ratings
load(sprintf('%sFineReader\\OCR_info_FineReader.mat', input_diqa2));
ocr_fine = ocr_dataset;

load(sprintf('%sOmnipage\\OCR_info_Omni.mat', input_diqa2));
ocr_omni = ocr_dataset;

load(sprintf('%sTesseract\\OCR_info_Tesseract.mat', input_diqa2));
ocr_tess = ocr_dataset;

recnum = 1;

% loop through each sub-directory of diqa1
for cnt = 1:13
    curr_path = sprintf('%sset%d\\', input_diqa1, cnt);
    curr_files = ls([curr_path '*.jpg']);
    for loop = 1:size(curr_files,1)
        fn1 = sprintf('%s%s', curr_path, curr_files(loop,:));
        fn2 = sprintf('DIQA_part1_set%02d_%s', cnt, curr_files(loop,:));
        fprintf('%s -> %s\n', fn1, fn2);
        copyfile(fn1, [output_diqa fn2]);
        if cnt ~= ocr_fine(recnum).set || ~strcmp(curr_files(loop,1:23),ocr_fine(recnum).name(1:23))
            error('record mis-match');
        end
        colA{recnum} = fn2;
        colB{recnum} = ocr_fine(recnum).accuracy;
        colC{recnum} = ocr_omni(recnum).accuracy;
        colD{recnum} = ocr_tess(recnum).accuracy;
        recnum = recnum + 1;
    end
end

% loop through each sub-directory of diqa2
for cnt = 14:25
    curr_path = sprintf('%sFineReader\\set%d\\', input_diqa2, cnt);
    curr_files = ls([curr_path '*.jpg']);
    for loop = 1:size(curr_files,1)
        fn1 = sprintf('%s%s', curr_path, curr_files(loop,:));
        fn2 = sprintf('DIQA_part2_set%02d_%s', cnt, curr_files(loop,:));
        fprintf('%s -> %s\n', fn1, fn2);
        copyfile(fn1, [output_diqa fn2]);

        if cnt ~= ocr_fine(recnum).set || ~strcmp(curr_files(loop,1:22),ocr_fine(recnum).name(1:22))
            error('record mis-match');
        end
        colA{recnum} = fn2;
        colB{recnum} = ocr_fine(recnum).accuracy;
        colC{recnum} = ocr_omni(recnum).accuracy;
        colD{recnum} = ocr_tess(recnum).accuracy;
        recnum = recnum + 1;
    end
end

if 0
    % write objective data to a spreadsheet. 
    xlswrite('diqa.xls',colA','sheet1','A2');
    xlswrite('diqa.xls',colB','sheet1','B2');
    xlswrite('diqa.xls',colC','sheet1','C2');
    xlswrite('diqa.xls',colD','sheet1','D2');
    
    xlswrite('diqa.xls',{'File'},'sheet1','A1');
    xlswrite('diqa.xls',{'FineReader'},'sheet1','B1');
    xlswrite('diqa.xls',{'Omnipage'},'sheet1','C1');
    xlswrite('diqa.xls',{'Tesseract'},'sheet1','D1');
end

