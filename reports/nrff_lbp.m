function [data] = nrff_lbp(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the LBP algorithm. 
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE


    switch mode
        case 'group'
            data = 'lbp';
        case 'feature_names'
            data{1} = 'lbp';
        case 'parameter_names'
            data{1} = 'lbp';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'parallelization'
            data = true; 
        case 'pixels'
            y = varargin{2};
            [numBlocks, deconstructed_image] = divideIntoMXMBlocks(3, y);
            LBP = zeros(1,numBlocks);
            for i = 1:length(deconstructed_image)
                currentBlock = deconstructed_image{i};
                [rowB, colB] = size(currentBlock);
                count = 0;
                for j = 1:rowB
                    for k = 1:colB
                        if j == 2 && k == 2
                            continue;
                        else
                            if rowB < 2 && colB < 2 %skip the middle pixel since that is the 'base' pixel
                                continue;
                            elseif rowB < 2 && colB >= 2
                                if currentBlock(j,k) - currentBlock(1,2) >= 0
                                    LBP(i) = LBP(i) + pow2(count);
                                end
                            elseif rowB >= 2 && colB < 2
                                if currentBlock(j,k) - currentBlock(2,1) >= 0
                                    LBP(i) = LBP(i) + pow2(count);
                                end
                            elseif currentBlock(j,k) - currentBlock(2,2) >= 0
                                LBP(i) = LBP(i) + pow2(count);
                            end
                        end
                        count = count + 1;
                    end
                end
            end
            data{1,1} = LBP;
        case 'pars'
            feature_data = varargin{1,1};
            data = mean(mean(feature_data{1}));
        otherwise
            error('Mode not recognized. Aborting.');
    end
end

function [count,deconstructed_image] = divideIntoMXMBlocks(m, y)
    [row, col] = size(y);
    count = 0;
    for i = 1:m:row % nested loop loops through each block
        for j = 1:m:col
            if i+m > row
                if j+m > col
                    temp{count + 1} = y(i:row, j:col);%reduces block size if necessary
                else
                    temp{count + 1} = y(i:row, j:(j+m-1));
                end
            elseif j+m > col
                temp{count + 1} = y(i:(i+m-1), j:col);
            else
                temp{count + 1} = y(i:(i+m-1), j:(j+m-1));
            end
            count = count+1;
        end
    end
    deconstructed_image = temp;
end
