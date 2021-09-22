function [data] = nrff_tdme(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the TDME algorithm. 
% Utilizes the discrete cosine transform to see if it can evaluate an
% image's quality through calculations to measure contrast
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
% Copyright Karen Panetta Tufts University
% karen@ece.tufts.edu


    switch mode
        case 'group'
            data = 'TDME';
        case 'feature_names'
            data{1} = 'TDME';
        case 'parameter_names'
            data{1} = 'TDME';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'pixels'
            y = varargin{2};

            data{1,1} = meas_tdme(y);
        case 'pars'
            feature_data = varargin{1,1};
            data = mean(feature_data{1});
        otherwise
            error('Mode not recognized. Aborting.');
    end
end



function meas = meas_tdme(Img)
% Img: input image
% return: TDME measure of enhancement in DCT domain

M = 8; % tile size for JPEG compression

[rows, cols] = size(Img);
Img = double(Img);

rows = rows - mod(rows,8);
cols = cols - mod(cols,8);

cnt = 0;
for rr = 1:M:rows
    for ss = 1:M:cols
        I_seg = Img(rr:rr+(M-1),ss:ss+(M-1));
        for k = 1:(M-1)
            ImgDCT_Lo = 0;
            ImgDCT_Hi = 0;
            cntHi = 0;
            cntLo = 0;
            ImgDCT = abs(dct2(I_seg));
            cntK = 0;
            for ii=1:M
                for jj=1:M
                    if ((ii>k)||(jj>k))
                        ImgDCT_Hi = ImgDCT_Hi+ImgDCT(ii,jj);
                        cntHi = cntHi+1;
                    else
                        ImgDCT_Lo = ImgDCT_Lo+ImgDCT(ii,jj);
                        cntLo = cntLo+1;
                    end
                end %jj
            end %ii
 
%             ImgDCT_Hi = ImgDCT_Hi/cntHi;
%             ImgDCT_Lo = ImgDCT_Lo/cntLo;
            
            meas_temp = ImgDCT_Hi/(ImgDCT_Hi+ImgDCT_Lo);
            cntK = cntK+1;
            if ~isnan(meas_temp)
                measIdx(cntK) = meas_temp;
            else
                measIdx(cntK) = 0;                
            end
        end %k
        cnt = cnt+1;
        meas_ii_jj(cnt) = mean(measIdx);
    end %ss
end %rr
meas = mean(meas_ii_jj);

end %function

