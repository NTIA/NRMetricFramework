function [data] = nrff_munsell_red(mode, varargin)

% No-Reference Feature Function (NRFF)
%
% Calculates Munsell Red from Margaret H. Pinson, "ITS4S: A Video Quality
% Dataset with Four-Second Unrepeated Scenes," NTIA Technical Memo
% TM-18-532, February 2018. https://www.its.bldrdoc.gov/publications/details.aspx?pub=3194
%
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%


    switch mode

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % overall name of this group of NR features
    case 'group'

        data = 'Munsell';

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create NR feature names
    case 'feature_names'

        data{1} = 'Munsell_Red';


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create NR parameter names (mean over time)
    case 'parameter_names'

        data{1} = 'Munsell_Red';


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % color space
    case 'luma_only'

        data = false;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % calculate features on 1 frame
    case 'read_mode'

        data = 'si';


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'pixels'

        %this component is the y component of the YCbCr which is the luma/grayscale component of the image
        y = varargin{2}; 
        cb = varargin{3}; 
        cr = varargin{4}; 

        % Recorganize pixels into a vector, with three planes (Y, Cb, Cr)
        [row,col] = size(y);

        ycbcr = nan(row*col, 3);
        ycbcr(:,1) = reshape(y,row*col,1);
        ycbcr(:,2) = reshape(cb,row*col,1);
        ycbcr(:,3) = reshape(cr,row*col,1);

        % convert from YCbCr color space to Munsell color space
        munsell = ycbcr2munsell(ycbcr);

        % Pick off the hue, value, and saturation. Even though we
        % don't use value now, we may need this later, so keep this code.
        hue = munsell(:,1); % [1..40] and nan
        % value = munsell(:,2); % [0..10]
        saturation = munsell(:,3); % [0..28]

        % Find red pixels
        red_pixels = find( saturation > 2 & ((hue >= 1 & hue <= 5) | (hue >= 33 & hue <= 40) ));

        % compute the fraction of red pixels
        data{1} = length(red_pixels) / (row * col);



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case 'pars'

       % compute NR parameters
       feature_data = varargin{1,1};

       % Mean over time, then square root.
       data(1) = nanmean(squeeze(feature_data{1}));
       data(1) = sqrt(data(1));


       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    otherwise

        error('Mode not recognized. Aborting.');

    end

end %of function   

   
