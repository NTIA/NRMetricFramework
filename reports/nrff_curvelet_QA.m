function [data] = nrff_curvelet_QA(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the CurveletQA algorithm. Code in the following repository is
% required, for the operation of this function:
%
%   https://github.com/utlive/CurveletQA
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
% This is a demonstration of No-reference image quality assessment in
% curvelet domain. The algorithm is described in: 
% 
% L. Liu, H. Dong, H. Huang, and A. C. Bovik, "No-reference image quality
% assessment in curvelet domain". Signal Processing: Image Communication, 2014.  
% 

    switch mode
        case 'group'
            data = 'curvelet_QA';
        case 'feature_names'
            data{1} = 'gauss_fit';
            data{2} = 'orientational_energy_mean_k';
            data{3} = 'orientational_energy_anisotropy';
            data{4} = 'gauss_fit_ori_en_combo';
        case 'parameter_names'
            data{1} = 'gauss_fit';
            data{2} = 'orientational_energy_mean_k';
            data{3} = 'orientational_energy_anisotropy';
            data{4} = 'gauss_fit_ori_en_combo';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'pixels'
            try
                %NOTE: MAKE SURE ALL FILES IN \curvelet_QA and
                %\curvelet_QA\fdct_usfft_matlab are added to the file path
                y = varargin{2}; 
                [numBlocks, deconstructed_image] = divideIntoMXMBlocks(256, y); %divide into group of 256x256 blocks
                f1_array = zeros(1,numBlocks); %preallocating data structures
                f2_array = zeros(1,numBlocks);
                f3_array = zeros(1,numBlocks);
                ff_array = zeros(1,numBlocks);
                for i = 1:length(deconstructed_image)
                    currentBlock = deconstructed_image{i};
                    [m, n] = size(currentBlock);
                    c = fdct_usfft(currentBlock, 1);
                    f1 = gaufit_n1(c);
                    f2 = ori_info3(c);
                    tempf1 = mean(f1); %added mean to isolate into one gaussian coefficient
                    tempf2 = f2(1);
                    tempf3 = f2(2);
                    f = [f1, f2];
                    f = f/(m*n);
                    f1_array(i) = mean(mean(tempf1));
                    f2_array(i) = mean(mean(tempf2));
                    f3_array(i) = mean(mean(tempf3));
                    ff_array(i) = sum(f);
                end
                data{1,1} = mean(f1_array);
                data{1,2} = mean(f2_array);
                data{1,3} = mean(f3_array);
                data{1,4} = mean(ff_array);
            catch
                % unknown errors in curvelet QA code
                data{1,1} = nan;
                data{1,2} = nan;
                data{1,3} = nan;
                data{1,4} = nan;
            end
        case 'pars'
            feature_data = varargin{1,1};
            data(1) = mean(feature_data{1});
            data(2) = mean(feature_data{2});
            data(3) = mean(feature_data{3});
            data(4) = mean(feature_data{4});
        otherwise
            error('Mode not recognized. Aborting.');
    end
end


%--------------------------------------------------------------
function [count,deconstructed_image] = divideIntoMXMBlocks(m, y)
    [row, col] = size(y);
    count = 0;
    for i = 1:m:row%nested loop loops through each block
        for j = 1:m:col
            if i+m > row
                if j+m > col
                    temp{count + 1} = y(i:row, j:col);%reduces block size if necessary
                else
                    temp{count + 1} = y(i:row, j:(j+m));
                end
            elseif j+m > col
                temp{count + 1} = y(i:(i+m), j:col);
            else
                temp{count + 1} = y(i:(i+m), j:(j+m));
            end
            count = count+1;
        end
    end
    deconstructed_image = temp;
end
