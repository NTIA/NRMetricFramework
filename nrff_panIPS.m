function [data] = nrff_panIPS(type, varargin)
% No-Reference Feature Function (NRFF)
%   Calculates the quality of camera pans in images per second (IPS).
%   IPS is the percentage of the image traveled in one second.
%
%   Returns the caluclated IPS value associated with the horizontal pan
%   motion and the vertical pan motion. For example given a 1920 by 1080 picture
%   if the image travels all the way accross the 1920 pixels it will have a
%   horizontal IPS value of 1.
%
%   Parameter #7, PanSpeed, is the most robust estimation of pan quality.
%   Parameter #8, PanSpeedNN, is an alternative that includes a neural
%                 network. Performance is inferior to PanSpeed.
%   Parameters #1 to #6 are other estimates of pan speed and jiggle that
%                 fed into the development of PanSpeed and PanSpeedNN
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
if strcmp(type, 'group')
    data = 'panIPS';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
elseif strcmp(type, 'feature_names') 
   
    data{1} = 'VertShift';
    data{2} = 'HorizShift';
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names
elseif strcmp(type, 'parameter_names')
   
	data = {'Pan-PrimaryMean', 'Pan-SecondaryMean', 'Pan-PrimaryStD', 'Pan-PrimaryMin',...
        'Pan-PrimaryMedian', 'Pan-DPrimaryMean', 'PanSpeed', 'PanSpeedNN'};
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
elseif strcmp(type, 'luma_only')
    data = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate with overlapping two frames
elseif strcmp(type, 'read_mode')
    data = 'ti';

        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(type, 'pixels')
    fps = varargin{1};
    if isnan(fps)
        fps = 0;
    end
    y = varargin{2};
    
    y1 = y(:,:,1);
    y2 = y(:,:,2);
    
    [row,col,frames] = size(y);
    if frames ~= 2
        error('This feature must be given exactly 2 frames in the "pixels" function call');
    end
    
    %Divide frame one into three portions and calculate meaningful values
    row6 = round(row/6);
    col6 = round(col/6);
    
    vt1 = y1(1*row6,:);
    ht1 = y1(:,1*col6);
    vmean1 = mean(vt1);
    vst1 = std(vt1);
    vmed1 = median(vt1);
    hmean1 = mean(ht1);
    hst1 = std(ht1);
    hmed1 = median(ht1);

    vt2 = y1(2*row6,:);
    ht2 = y1(:,2*col6);
    vmean2 = mean(vt2);
    vst2 = std(vt2);
    vmed2 = median(vt2);
    hmean2 = mean(ht2);
    hst2 = std(ht2);
    hmed2 = median(ht2);

    vt3 = y1(3*row6,:);
    ht3 = y1(:,3*col6);
    vmean3 = mean(vt3);
    vst3 = std(vt3);
    vmed3 = median(vt3);
    hmean3 = mean(ht3);
    hst3 = std(ht3);
    hmed3 = median(ht3);
    
    vt4 = y1(4*row6,:);
    ht4 = y1(:,4*col6);
    vmean4 = mean(vt4);
    vst4 = std(vt4);
    vmed4 = median(vt4);
    hmean4 = mean(ht4);
    hst4 = std(ht4);
    hmed4 = median(ht4);
    
    vt5 = y1(5*row6,:);
    ht5 = y1(:,5*col6);
    vmean5 = mean(vt5);
    vst5 = std(vt5);
    vmed5 = median(vt5);
    hmean5 = mean(ht5);
    hst5 = std(ht5);
    hmed5 = median(ht5);
    
    %Calculate the same values for entire second frame
    Nvmean = mean(y2,2);
    Nvstd = std(y2,0,2);
    Nvmed = median(y2,2);
    Nhmean = mean(y2,1);
    Nhstd = std(y2,0,1);
    Nhmed = median(y2,1);
    
    %Find the positions of the values associated with first frame in the
    %second frame. Note, the weights should be 2*mean + 3*std + 2*median.
    [~,vpos1] = min(2*abs(Nvmean(:) - vmean1) + 3 * abs(Nvstd(:) - vst1) +...
        + 2 * abs(Nvmed(:) - vmed1));
    [~,hpos1] = min(2*abs(Nhmean(:) - hmean1) + 3 * abs(Nhstd(:) - hst1) +...
        2 * abs(Nhmed(:) - hmed1));
    [~,vpos2] = min(2*abs(Nvmean(:) - vmean2) + 3 * abs(Nvstd(:) - vst2) +...
        + 2 * abs(Nvmed(:) - vmed2));
    [~,hpos2] = min(2*abs(Nhmean(:) - hmean2) + 3 * abs(Nhstd(:) - hst2) +...
        2 * abs(Nhmed(:) - hmed2));
    [~,vpos3] = min(2*abs(Nvmean(:) - vmean3) + 3 * abs(Nvstd(:) - vst3) +...
        + 2 * abs(Nvmed(:) - vmed3));
    [~,hpos3] = min(2*abs(Nhmean(:) - hmean3) + 3 * abs(Nhstd(:) - hst3) +...
        2 * abs(Nhmed(:) - hmed3));
    [~,vpos4] = min(2*abs(Nvmean(:) - vmean4) + 3 * abs(Nvstd(:) - vst4) +...
        + 2 * abs(Nvmed(:) - vmed4));
    [~,hpos4] = min(2*abs(Nhmean(:) - hmean4) + 3 * abs(Nhstd(:) - hst4) +...
        2 * abs(Nhmed(:) - hmed4));
    [~,vpos5] = min(2*abs(Nvmean(:) - vmean5) + 3 * abs(Nvstd(:) - vst5) +...
        + 2 * abs(Nvmed(:) - vmed5));
    [~,hpos5] = min(2*abs(Nhmean(:) - hmean5) + 3 * abs(Nhstd(:) - hst5) +...
        2 * abs(Nhmed(:) - hmed5));
    
    %Calculate the IPS value from the change and take the median value of
    %the three
    iv = zeros(5,1);
    ih = zeros(5,1);
    iv(1,1) = (row6-vpos1)*fps/row;
    iv(2,1) = (2*row6-vpos2)*fps/row;
    iv(3,1) = (3*row6-vpos3)*fps/row;
    iv(4,1) = (4*row6-vpos4)*fps/row;
    iv(5,1) = (5*row6-vpos5)*fps/row;
    ih(1,1) = (col6-hpos1)*fps/col;
    ih(2,1) = (2*col6-hpos2)*fps/col;
    ih(3,1) = (3*col6-hpos3)*fps/col;
    ih(4,1) = (4*col6-hpos4)*fps/col;
    ih(5,1) = (5*col6-hpos5)*fps/col;
    
    bigv = abs(iv(:,1)) > 3;
    bigh = abs(ih(:,1)) > 3;
    
    iv(bigv == 1) = NaN;
    ih(bigh == 1) = NaN;
    
    data{1} = nanmedian(iv);
    data{2} = nanmedian(ih);
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
elseif strcmp(type, 'pars')
    
    feature_data = varargin{1,1};

    % rename features with meaningful names
    vert = feature_data{1};
    horiz = feature_data{2};

    % turn off warning for 0-by-0 matrix returning NaN
    warning('off','MATLAB:mode:EmptyInput');

    % Remove noise if value should be zero
    if nanmedian(vert) == 0
        vert(:) = 0;
    end
    
    if nanmedian(horiz) == 0
        horiz(:) = 0;
    end
    
    % Remove outliers from data
    TF = isoutlier(horiz, 'quartiles');
    horiz(TF == 1) = NaN;
    TF = isoutlier(vert, 'quartiles');
    vert(TF == 1) = NaN;
    
    %Calculate stats in horizontal and vertical direction
    HorizMean = transpose(nanmean(abs(horiz)));
    VertMean = transpose(nanmean(abs(vert)));
    HorizStD = transpose(nanstd(horiz));
    VertStD = transpose(nanstd(vert));
    HorizMin = HorizMean - HorizStD;
    VertMin = VertMean - VertStD;
    HorizMedian = transpose(nanmedian(horiz));
    VertMedian = transpose(nanmedian(vert));

    %Calculate the derevitives of the stats
    Dhoriz = diff(horiz);
    Dvert = diff(vert);
    
    DHorizMean = transpose(nanmean(abs(Dhoriz)));
    DVertMean = transpose(nanmean(abs(Dvert)));

    %Transfer horizontal values into primary and secondary directions
    PrimaryMean = (HorizMean.^2 + VertMean.^2).^(1/2);
    PrimaryStD = (HorizStD.^2 + VertStD.^2).^(1/2);
    PrimaryMin = (HorizMin.^2 + VertMin.^2).^(1/2);
    PrimaryMedian = (HorizMedian.^2 + VertMedian.^2).^(1/2);
    DPrimaryMean = (DHorizMean.^2 + DVertMean.^2).^(1/2);

    acalc = @(x,y) x.*sin(atan(y./x)).*(x~=0);

    SecondaryMean = acalc(HorizMean,VertMean);
    
    %Nessecary Parameters
    data(1,1) = PrimaryMean;
    data(1,2) = SecondaryMean;
    data(1,3) = PrimaryStD;
    data(1,4) = PrimaryMin;
    data(1,5) = PrimaryMedian;
    data(1,6) = DPrimaryMean;
    
    
    %Quality Predictions
    [LinearQuality, NeuralQuality] = predictQuality(PrimaryMin,...
        PrimaryMedian,DPrimaryMean);
    data(1,7) = LinearQuality;
    data(1,8) = NeuralQuality;
    
    % replace NaN with no impairment.
    for cnt=1:6
        if isnan(data(cnt))
            data(cnt) = 0;
        end
    end
    if isnan(data(7))
        data(7) = 0.94884970353605 * 3.34 + 1.5; % approximately 4.67;
    end
    if isnan(data(8))
        data(8) = 4.42;
    end
    
    for cnt=1:length(data)
    end
    
    % turn on warning for 0-by-0 matrix returning NaN
    warning('on','MATLAB:mode:EmptyInput');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
else
    error('Mode not recognized. Aborting.');
end
end


function [LQuality, NQuality] = predictQuality(pmin,pmed,dpm)
% Normalize Inputs
pmin = (pmin/1.40625).^(0.5);
pmed = (pmed/1.775).^(0.5);
dpm = dpm/0.9751738202;

% Calculate Linear Quality
lnq = -0.604179930075768*pmin-0.223849446288641*pmed...
    -0.285468123932075*dpm + 0.94884970353605;

% Calculate Neural Quality
% Declare Constants
tansig = @(n) 2./(1 + exp(-2*n)) - 1;

% Declare constants
bias1 = [-3.1347922649972059794;3.7038189823761369368;1.9383579789823972561;-3.0988236950766618882;2.177894159837903576;1.720094013802780708;-0.35251774905806787519;-0.138959535300914927;-0.16570668805449922933;0.015759194963006928347;1.3421026190717677551;0.12740487569771280496;-2.0573966098053082519;-3.5101774426799110529;2.8034396449727210232;3.969314941073709857];
weights1 = [3.5671461262933452652 0.065218799567553664698 -0.61685071400501489958;-0.046405599843009126548 2.3594865503118604977 1.7856820525382857134;-0.98623428972404925119 -2.6916059979987800865 -2.0244310437956509752;2.7751797214200371045 -0.55427250298391206318 -2.0982853533867542595;-2.4709524567081695423 -1.4429503108716144055 -3.2902999358758462378;-2.3225487882660020844 3.5482098606938605734 0.9498235641628882675;-3.296850150384603495 -1.5526248521941181657 1.2796799421884210712;2.3374410035803254715 -2.7756793235473979919 -0.49143408027799012627;-2.5435529629202640045 1.5998010368311130769 -1.886462050211862751;-2.3279693338046292261 -1.4466313041444072152 -2.39663307227767719;0.073877720545727318391 3.6148167624419551558 0.30471158265414227673;2.7116268920397224029 -2.2515576485868180612 -1.9241797166194944957;-2.0428143601828678833 2.5198606187941825496 -1.5929982321391205069;-2.8015070158530521738 -0.050887120748909546453 -2.5304758400888793801;0.82982836248299673976 2.3509607139176269541 2.654870500589652238;2.9965148571608897221 2.4006711217962650728 2.4527298112041808764];

bias2 = -0.19906189095081011642;
weights2 = [-0.38378084367706521984 1.4774368627611402793 -0.93914726080990873491 0.68920453255421376682 1.279188325212890609 -1.6514198718533388277 0.43671155315939624852 -1.0331492420564793999 -0.71381495914883918985 0.37914589959271338682 0.13005596698555690893 0.52912375092692387479 -0.52238387390894880369 1.4006488878055392 -0.35410327711760830605 1.0943732368000742561];

% Solve network
X = [pmin,pmed,dpm];
X = X';
X1 = X.*[2;2.14405497643192;2] - 1;

L1 = tansig(bias1 + weights1*X1);
L2 = bias2 + weights2*L1;

Y = (L2+1)/2;
nnq = Y';

% Denormalize Outputs
LQuality = lnq*3.34 + 1.5;
NQuality = nnq*3.34 + 1.5;
end
