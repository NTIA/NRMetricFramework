function [data] = nrff_jp2knr(mode, varargin)
% No-Reference Feature Function (NRFF)
%
% Calculates the JNB algorithm from:
%
% R. Ferzli and L. J. Karam, "A No-Reference Objective Image Sharpness
% Metric Based on the Notion of Just Noticeable Blur (JNB)," in IEEE
% Transactions on Image Processing, vol. 18, no. 4, pp. 717-728, April
% 2009, doi: 10.1109/TIP.2008.2011760.
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%
% SOFTWARE DISCLAIMER / RELEASE
% 
% -----------COPYRIGHT NOTICE STARTS WITH THIS LINE------------
% Copyright (c) 2003 The University of Texas at Austin
% All rights reserved.
% 
% Permission is hereby granted, without written agreement and without license or royalty fees, to use, copy, 
% modify, and distribute this code (the source files) and its documentation for
% any purpose, provided that the copyright notice in its entirety appear in all copies of this code, and the 
% original source of this code, Laboratory for Image and Video Engineering (LIVE, http://live.ece.utexas.edu)
% and Center for Perceptual Systems (CPS, http://www.cps.utexas.edu) at the University of Texas at Austin (UT Austin, 
% http://www.utexas.edu), is acknowledged in any publication that reports research using this code. The research
% is to be cited in the bibliography as:
% 
% H. R. Sheikh,  A. C. Bovik and L. Cormack, "No-Reference Quality
% Assessment using Natural Scene Statistics: JPEG2000"., IEEE Transactions on Image Processing, (to appear).
% 
% IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, 
% OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS DATABASE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF TEXAS
% AT AUSTIN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% THE UNIVERSITY OF TEXAS AT AUSTIN SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE DATABASE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS,
% AND THE UNIVERSITY OF TEXAS AT AUSTIN HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
% 
% -----------COPYRIGHT NOTICE ENDS WITH THIS LINE------------

    switch mode
        case 'group'
            data = 'jp2knr';
        case 'feature_names'
            data{1} = 'jp2knr';
        case 'parameter_names'
            data{1} = 'jp2knr';
        case 'luma_only'
            data = true;
        case 'read_mode'
            data = 'si';
        case 'parallelization'
            data = true; 
        case 'pixels'
            img = varargin{2};
            L = 4;
            wname = 'bior4.4';
            load jp2knr_train_all;

            wavetree=image_wtransform(img,L, wname);
            imh=jointhist(wavetree);
            for j=1:13
                temp=wavetree{j};,temp=(abs(temp(:)));,temp(temp==0)=min(nonzeros(temp));,temp=log2(temp);
                u(j)=mean(temp);,s(j)=std(temp);, ss(j)=s(j).^2;
            end

            th_off_P=th_off(1);, th_off_C=th_off(2);
            p=binarized_params_img(m_uu, th_off_P, th_off_C, u, imh);

            p=p(:,3:4:end);

            fitfun=inline('t(1).*(1-exp(-(x-t(2))./t(3)))','t','x');

            q=zeros(size(p));
            for i=1:6
                q(i)=fitfun(t(:,i),p(i));
            end

            %combine subbands
            q=[mean(q(1:2)) q(3) mean(q(4:5)) q(6)];

            %weighted average
            q=q*w;
            data{1,1} = q;
        case 'pars'
            feature_data = varargin{1,1};
            data(1) = mean(feature_data{1});
        otherwise
            error('Mode not recognized. Aborting.');
    end
    
end


function wavetree=image_wtransform(yo, L, wname)

% -----------COPYRIGHT NOTICE STARTS WITH THIS LINE------------
% Copyright (c) 2003 The University of Texas at Austin
% All rights reserved.
% 
% Permission is hereby granted, without written agreement and without license or royalty fees, to use, copy, 
% modify, and distribute this code (the source files) and its documentation for
% any purpose, provided that the copyright notice in its entirety appear in all copies of this code, and the 
% original source of this code, Laboratory for Image and Video Engineering (LIVE, http://live.ece.utexas.edu)
% and Center for Perceptual Systems (CPS, http://www.cps.utexas.edu) at the University of Texas at Austin (UT Austin, 
% http://www.utexas.edu), is acknowledged in any publication that reports research using this code. The research
% is to be cited in the bibliography as:
% 
% H. R. Sheikh,  A. C. Bovik and L. Cormack, "No-Reference Quality
% Assessment using Natural Scene Statistics: JPEG2000"., IEEE Transactions on Image Processing, accepted April. 2004.
% 
% IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, 
% OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS DATABASE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF TEXAS
% AT AUSTIN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% THE UNIVERSITY OF TEXAS AT AUSTIN SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE DATABASE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS,
% AND THE UNIVERSITY OF TEXAS AT AUSTIN HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
% 
% -----------COPYRIGHT NOTICE ENDS WITH THIS LINE------------


    yo=yo./sqrt(mean(yo(:).^2)); % all images will now have rms pixel values = 1.0

    % compute wlevs level wavelet transform
    [lod,hid,lor,hir]=wfilters(wname);

    [C,S]=wavedec2(yo,L,lod,hid);

    % do abs 
    C=abs(C);

    wavetree=cell(4+(L-1)*3,1);

    wavetree{1}=reshape(C(1:prod(S(1,:))), S(1,1), S(1,2));
    offset=prod(S(1,:));
    for i=1:L
        sizedetail=S(i+1,:);
        wavetree{(i-1)*3+2}=reshape(C(offset+1:offset+prod(sizedetail)), sizedetail(1),sizedetail(2)); %Horizontal details
        offset=offset+prod(sizedetail);

        wavetree{(i-1)*3+3}=reshape(C(offset+1:offset+prod(sizedetail)), sizedetail(1),sizedetail(2)); %Detail details
        offset=offset+prod(sizedetail);

        wavetree{(i-1)*3+4}=reshape(C(offset+1:offset+prod(sizedetail)), sizedetail(1),sizedetail(2)); %Diagonal details
        offset=offset+prod(sizedetail);
    end

    % select the center of each subband such that the sizes of subbands are simple powers of two multiples of the coarsest level
    sznew=floor(S(end,:)./2^L);
    temp=wavetree{1};
    sz=size(temp);
    offset=floor((sz-sznew)./2);
    wavetree{1}=temp(offset(1)+1:offset(1)+sznew(1), offset(2)+1:offset(2)+sznew(2));
    for i=1:L
        temp=wavetree{(i-1)*3+2};
        sz=size(temp);
        offset=floor((sz-sznew)./2);
        wavetree{(i-1)*3+2}=temp(offset(1)+1:offset(1)+sznew(1), offset(2)+1:offset(2)+sznew(2));

        temp=wavetree{(i-1)*3+3};
        wavetree{(i-1)*3+3}=temp(offset(1)+1:offset(1)+sznew(1), offset(2)+1:offset(2)+sznew(2));

        temp=wavetree{(i-1)*3+4};
        wavetree{(i-1)*3+4}=temp(offset(1)+1:offset(1)+sznew(1), offset(2)+1:offset(2)+sznew(2));
        sznew=sznew*2;
    end

end


function hh=jointhist(wavetree)
% -----------COPYRIGHT NOTICE STARTS WITH THIS LINE------------
% Copyright (c) 2003 The University of Texas at Austin
% All rights reserved.
% 
% Permission is hereby granted, without written agreement and without license or royalty fees, to use, copy, 
% modify, and distribute this code (the source files) and its documentation for
% any purpose, provided that the copyright notice in its entirety appear in all copies of this code, and the 
% original source of this code, Laboratory for Image and Video Engineering (LIVE, http://live.ece.utexas.edu)
% and Center for Perceptual Systems (CPS, http://www.cps.utexas.edu) at the University of Texas at Austin (UT Austin, 
% http://www.utexas.edu), is acknowledged in any publication that reports research using this code. The research
% is to be cited in the bibliography as:
% 
% H. R. Sheikh,  A. C. Bovik and L. Cormack, "No-Reference Quality
% Assessment using Natural Scene Statistics: JPEG2000"., IEEE Transactions on Image Processing, (to appear).
% 
% IN NO EVENT SHALL THE UNIVERSITY OF TEXAS AT AUSTIN BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, 
% OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OF THIS DATABASE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF TEXAS
% AT AUSTIN HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
% 
% THE UNIVERSITY OF TEXAS AT AUSTIN SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE DATABASE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS,
% AND THE UNIVERSITY OF TEXAS AT AUSTIN HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
% 
% -----------COPYRIGHT NOTICE ENDS WITH THIS LINE------------


    L=4;
    Nbins=128;
    hh=zeros(3*(L-1),Nbins,Nbins);

    for level=L:-1:2
        for orientation=1:3
            numparents=level-1;
            C = wavetree{1+(level-1)*3+orientation};
            % extend C symmetrically by one pixel for windowing 
            C=[C(1,:); C; C(end,:)];, C=[C(:,1) C C(:,end)];

            rows=size(C,1);
            cols=size(C,2);

            qs=[]; % coefficients to form prediction
            cs=[]; % these will be predicted from qs


            % assemble coefficients that will make the prediction
            rowindices=1:size(C,1)-2;
            colindices=1:size(C,2)-2;

            % indices of prediction coeffs in the same level.
            % 1 4 7
            % 2 X 8
            % 3 6 9
            ind=[2 4 6 8];
            for i=1:length(ind)
                rowoff=mod(ind(i)-1,3);
                coloff=floor((ind(i)-1)./3);
                temp=C(rowindices+rowoff, colindices+coloff);
                qs=cat(1,qs,temp(:)');
            end


            for i=1:numparents % assemble from parents!
                temp = imresize(wavetree{1+(level-i-1)*3+orientation}, 2^i, 'nearest');
                qs=cat(1,qs,temp(:)');
            end


            temp=C(2:end-1,2:end-1);
            cs=temp(:)';

            w=qs'\cs'; % prediction weights
            lq=(qs'*w)'; % do predictions


            %         % clip to strictly positive values, else log will screw up! the predictor could go negative!
            lq(lq <= 0) = min(lq(lq>0));

            % calculate and save the error in prediction
            lcs=log2(cs); % log of coef
            llq=log2(lq); % log of prediction


            % construct 2d conditional histogram
            xmin=-25;, xmax=5;, ymin=-25;,  ymax=5;

            % plot 2d pdf
            h=histogram2(llq,lcs,Nbins); %hist2d is not compatible with current version of matlab ergo histogram2 is used instead
            axis([xmin,xmax,ymin,ymax]); %added since histogram2 function cannot set axes limits

            % convert to 2d pdf
            h=h.Values./sum(h.Values(:)); %.Values used to isolate values used in histogram cluster
            hh((level-2)*3+orientation,:,:)=h;
        end
    end
end

function p=binarized_params_img(m_uu, th_off_P, th_off_C, u, imh)
% convert thresholds into indices of histogram
    temp=linspace(-25,5,126);


    % compute image dependentthresholds
    uc = (u(2:end))';
    uc=([mean(uc(1:2)); uc(3); mean(uc(4:5)); uc(6); mean(uc(7:8)); uc(9); mean(uc(10:11)); uc(12)]); % combine h-v

    % calculate prediction for subband means from upper subbands
    % fit line from coarser levels
    t=ones(4,1)\(uc(1:4)-m_uu*(1:4)'); %fit lines, only the y-intercept

    u_pred=[(1:8)' ones(8,1)]*[m_uu;t];
    th1=u_pred([5 5 6 7 7 8])+th_off_P; %rhresholds for P
    th2=u_pred([5 5 6 7 7 8])+th_off_C;

    thresh=zeros(1,length(th1)*2);

    % see below as to how the code expects the thresholds
    thresh(2:2:end)=th2;
    thresh(1:2:end)=th1;


    % change threshold to index
    for j=1:length(thresh)
        if length(max(find(thresh(j) > temp))) == 0 %if statement added here to prevent potential size issues
            thresh(j) = 0;
        else
            thresh(j)=max(find(thresh(j) > temp));
        end
    end


    imh=imh(4:9,:,:); % lowest two detail levels
    % 2nd finest
    Tv=thresh(1);, Th=thresh(2);% Tv is threshold on P, Th is threshold on C
    pii=sum(sum(squeeze(imh(1,1:Th,1:Tv))));
    psi=sum(sum(squeeze(imh(1,1:Th,Tv+1:end)))); % C is insig and P is sig
    pss=sum(sum(squeeze(imh(1,Th+1:end,Tv+1:end))));
    pis=sum(sum(squeeze(imh(1,Th+1:end,1:Tv)))); % P is insig and C is sig
    ph2=[pii pis pss psi];

    Tv=thresh(3);, Th=thresh(4);
    pii=sum(sum(squeeze(imh(2,1:Th,1:Tv))));
    psi=sum(sum(squeeze(imh(2,1:Th,Tv+1:end))));
    pss=sum(sum(squeeze(imh(2,Th+1:end,Tv+1:end))));
    pis=sum(sum(squeeze(imh(2,Th+1:end,1:Tv))));
    pv2=[pii pis pss psi];

    Tv=thresh(5);, Th=thresh(6);
    pii=sum(sum(squeeze(imh(3,1:Th,1:Tv))));
    psi=sum(sum(squeeze(imh(3,1:Th,Tv+1:end))));
    pss=sum(sum(squeeze(imh(3,Th+1:end,Tv+1:end))));
    pis=sum(sum(squeeze(imh(3,Th+1:end,1:Tv))));
    pd2=[pii pis pss psi];

    % finest
    Tv=thresh(7);, Th=thresh(8);
    pii=sum(sum(squeeze(imh(4,1:Th,1:Tv))));
    psi=sum(sum(squeeze(imh(4,1:Th,Tv+1:end))));
    pss=sum(sum(squeeze(imh(4,Th+1:end,Tv+1:end))));
    pis=sum(sum(squeeze(imh(4,Th+1:end,1:Tv))));
    ph1=[pii pis pss psi];

    Tv=thresh(9);, Th=thresh(10);
    pii=sum(sum(squeeze(imh(5,1:Th,1:Tv))));
    psi=sum(sum(squeeze(imh(5,1:Th,Tv+1:end))));
    pss=sum(sum(squeeze(imh(5,Th+1:end,Tv+1:end))));
    pis=sum(sum(squeeze(imh(5,Th+1:end,1:Tv))));
    pv1=[pii pis pss psi];

    Tv=thresh(11);, Th=thresh(12);
    pii=sum(sum(squeeze(imh(6,1:Th,1:Tv))));
    psi=sum(sum(squeeze(imh(6,1:Th,Tv+1:end))));
    pss=sum(sum(squeeze(imh(6,Th+1:end,Tv+1:end))));
    pis=sum(sum(squeeze(imh(6,Th+1:end,1:Tv))));
    pd1=[pii pis pss psi];

    p=[ph2 pv2 pd2 ph1 pv1 pd1];
end
