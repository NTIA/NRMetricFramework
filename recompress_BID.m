% The Blurrerd Image Database (BID) is available from 
% http://www02.smt.ufrj.br/~eduardo/ImageDatabase.htm
% BID contains JPEG images. As of January 2020, MATLAB's imread function
% has unpredictable problems when reading these images. Sometimes the
% images are read correctly, and sometimes an unknown problem occurs.
%
% This script moves the BID images into a subdirectory (named "original") 
% and recompresses each image as a lossless JPEG. This ensures no
% additional impairment is added to the image. 
%

success = mkdir([bid_dataset.path 'original\']);
if ~success
    error('could not make subdirectory %soriginal', bid_dataset.path);
end

for cnt=1:length(bid_dataset.media)
    success = movefile([bid_dataset.path bid_dataset.media(cnt).file], ...
        [bid_dataset.path 'original\']);
    
    if ~success
        error('could not move file %s into subdirectory',  bid_dataset.media(cnt).file);
    end    
end

for cnt=1:length(bid_dataset.media)
    img = imread([bid_dataset.path 'original\' bid_dataset.media(cnt).file], 'jpg');
    
    imwrite(img, [bid_dataset.path bid_dataset.media(cnt).file], 'jpg', ...
        'Quality', 100, 'Mode', 'lossless');
end

