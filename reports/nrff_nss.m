function [data] = nrff_nss(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the algorithms in the following paper:
%    Y. Fang, K. Ma, Z. Wang, W. Lin, Z. Fang and G. Zhai, "No-Reference
%    Quality Assessment of Contrast-Distorted Images Based on Natural Scene
%    Statistics," in IEEE Signal Processing Letters, vol. 22, no. 7, pp.
%    838-842, July 2015, doi: 10.1109/LSP.2014.2372333.
%
% This code was obtained from https://github.com/steffensbola/blind_iqa_contrast
%
% The following *.mat files were re-named to avoid possible naming
% conflicts: CID2013.mat -> nss_CID2013.mat, CSIQ.mat -> nss_CSIQ.mat, and
% TID13.mat -> nss_TID13.mat
%
% Warning: This function requires a different version of
% svmpredict.mex than is distributed with NRMetricFramework repository.
% Download the appropriate version from the author's website,
% https://github.com/steffensbola/blind_iqa_contrast, subdirectory NSS.   
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
%
% MIT License
% 
% Copyright (c) 2019 Cristiano Rafael Steffens
% 
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
% 
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

switch mode
    case 'group'
        data = 'nss';
    case 'feature_names'
        data{1} = 'nss_cid';
        data{2} = 'nss_csiq';
        data{3} = 'nss_tid';
    case 'parameter_names'
        data{1} = 'nss_cid';
        data{2} = 'nss_csiq';
        data{3} = 'nss_tid';
    case 'luma_only'
        data = true;
    case 'read_mode'
        data = 'si';
    case 'parallelization'
        data = true; 
    case 'pixels'
        load nss_CID2013.mat
        CID_dis_matrix = Data; %renaming to create data convention
        clear Data;
        load nss_CSIQ.mat
        load nss_TID13.mat
        train_cid_data = CID_dis_matrix(:,[1:5]); %first five columns used for training data
        train_cid_label = CID_dis_matrix(:, 6); %last column used for labels
        train_csiq_data = ref_CSIQ_dis_matrix(:,[1:5]);
        train_csiq_label = ref_CSIQ_dis_matrix(:,6);
        train_tid_data = TID_dis_matrix(:, [1:5]);
        train_tid_label = TID_dis_matrix(:, 6);
        
        model_cid = svmtrain(train_cid_label, train_cid_data, '-s 3');
        model_csiq = svmtrain(train_csiq_label, train_csiq_data, '-s 3');
        model_tid = svmtrain(train_tid_label, train_tid_data, '-s 3');
        
        
        y = varargin{2};
        
        i = 1;
        
        mean_tmp = round(mean2(y));
        Value(i, 1) = 1/(sqrt(2*pi)*26.0625)*exp(-(mean_tmp-118.5585)^2/(2*26.0625^2));
        
        std_tmp = round(std2(y));
        Value(i, 2) = 1/(sqrt(2*pi)*12.8584)*exp(-(std_tmp-57.2743)^2/(2*12.8584^2));
        
        entropy_tmp = entropy(y);
        Value(i, 3) = 1/0.2578*exp((entropy_tmp-7.5404)/0.2578)*exp(-exp((entropy_tmp-7.5404)/0.2578));
        
        kurtosis_tmp = kurtosis(double(y(:)));
        Value(i, 4) = sqrt(19.3174/(2*pi*kurtosis_tmp^3))*exp(-19.3174*(kurtosis_tmp-2.7292)^2/(2*(2.7292^2)*kurtosis_tmp));
        
        skewness_tmp = skewness(double(y(:)));
        Value(i, 5) = 1/(sqrt(2*pi)*0.6319)*exp(-(skewness_tmp-0.1799)^2/(2*0.6319^2));
        
        test_label = 0;
        [predicted_label_cid, accuracy_cid, decision_values_cid] = svmpredict(test_label, Value, model_cid);
        [predicted_label_csiq, accuracy_csiq, decision_values_csiq] = svmpredict(test_label, Value, model_csiq);
        [predicted_label_tid, accuracy_tid, decision_values_tid] = svmpredict(test_label, Value, model_tid);
        data{1,1} = predicted_label_cid;
        data{1,2} = predicted_label_csiq;
        data{1,3} = predicted_label_tid;
    case 'pars'
        feature_data = varargin{1,1};
        data(1) = mean(feature_data{1});
        data(2) = mean(feature_data{2});
        data(3) = mean(feature_data{3});
    otherwise
        error('Mode not recognized. Aborting');
end