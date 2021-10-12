function [data] = nrff_tdmech(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the TDMECH algorithm. 
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
% Copyright Karen Panetta Tufts University
% karen@ece.tufts.edu


    switch mode
        case 'group'
            data = 'TDMECH';
        case 'feature_names'
            data{1} = 'TDMECH';
        case 'parameter_names'
            data{1} = 'TDMECH';
        case 'luma_only'
            data = false;
        case 'read_mode'
            data = 'si';
        case 'pixels'
            y = varargin{2};
            cb = varargin{3};
            cr = varargin{4};

            data{1,1} = meas_tdmec_xmitter(y, cb, cr);
        case 'pars'
            feature_data = varargin{1,1};
            data = mean(feature_data{1});
        otherwise
            error('Mode not recognized. Aborting.');
    end
end


function meas = meas_tdmec_xmitter(Img_y, Img_cb, Img_cr)
% Img: input color image 
% return: TDME measure of enhancement in DCT domain

    [rows, cols] = size(Img_y(:,:));

    rows = rows - mod(rows,8);
    cols = cols - mod(cols,8);

    cnt = 0;
    for rr = 1:8:rows
        for ss = 1:8:cols
    %         I_seg = Img(rr:rr+7,ss:ss+7);
            I_seg_y = Img_y(rr:rr+7,ss:ss+7);
            I_seg_cb = Img_cb(rr:rr+7,ss:ss+7);
            I_seg_cr = Img_cr(rr:rr+7,ss:ss+7);
            for k = 1:7
                ImgDCT_Lo = 0;
                ImgDCT_Hi = 0;
                ImgDCT_Lo_y = 0;
                ImgDCT_Hi_y = 0;
                ImgDCT_Lo_cb = 0;
                ImgDCT_Hi_cb = 0;
                ImgDCT_Lo_cr = 0;
                ImgDCT_Hi_cr = 0;
                cntHi = 0;
                cntLo = 0;
                ImgDCT_y = abs(dct2(I_seg_y));
                ImgDCT_cb = abs(dct2(I_seg_cb));
                ImgDCT_cr = abs(dct2(I_seg_cr));
                cntK = 0;
                for ii=1:8
                    for jj=1:8
                        if ((ii>k)||(jj>k))
                            ImgDCT_Hi_y = ImgDCT_Hi_y+ImgDCT_y(ii,jj);
                            ImgDCT_Hi_cb = ImgDCT_Hi_cb+ImgDCT_cb(ii,jj);
                            ImgDCT_Hi_cr = ImgDCT_Hi_cr+ImgDCT_cr(ii,jj);                        
                            cntHi = cntHi+1;
                        else
                            ImgDCT_Lo_y = ImgDCT_Lo_y+ImgDCT_y(ii,jj);
                            ImgDCT_Lo_cb = ImgDCT_Lo_cb+ImgDCT_cb(ii,jj);
                            ImgDCT_Lo_cr = ImgDCT_Lo_cr+ImgDCT_cr(ii,jj);
                            cntLo = cntLo+1;
                        end
                    end %jj
                end %ii

                meas_temp_y = ImgDCT_Hi_y/(ImgDCT_Hi_y+ImgDCT_Lo_y);
                meas_temp_cb = ImgDCT_Hi_cb/(ImgDCT_Hi_cb+ImgDCT_Lo_cb);
                meas_temp_cr = ImgDCT_Hi_cr/(ImgDCT_Hi_cr+ImgDCT_Lo_cr);
                cntK = cntK+1;

                if ~isnan(meas_temp_y)
                    measIdx_y(cntK) = meas_temp_y;
                else
                    measIdx_y(cntK) = 0;                
                end

                if ~isnan(meas_temp_cb)
                    measIdx_cb(cntK) = meas_temp_cb;
                else
                    measIdx_cb(cntK) = 0;                
                end

                if ~isnan(meas_temp_cr)
                    measIdx_cr(cntK) = meas_temp_cr;
                else
                    measIdx_cr(cntK) = 0;                
                end

            end %k
            cnt = cnt+1;
            meas_ii_jj_y(cnt) = mean(measIdx_y);
            meas_ii_jj_cb(cnt) = mean(measIdx_cb);
            meas_ii_jj_cr(cnt) = mean(measIdx_cr);

            coeff_y = 0;%rms(rms(I_seg_y));
            coeff_cb = -rms(rms(I_seg_cb));
            coeff_cr = -rms(rms(I_seg_cr));

            meas_lum_temp = meas_ii_jj_y(cnt) * coeff_y;
            meas_ch_temp = (meas_ii_jj_cb(cnt) * coeff_cb + meas_ii_jj_cr(cnt) * coeff_cr)/2;
            meas_ii_jj(cnt) = (meas_lum_temp + meas_ch_temp )/2;

        end %ss
    end %rr
    meas = mean(meas_ii_jj);

end %function

