function [data] = nrff_brisque(mode, varargin)
%
% No-Reference Feature Function (NRFF)
% 
% Calculates BRISQUE score as implemented by The MathWorks, Inc. 2016-2019.
%
% Utilizes MATLAB's support vector regression model that is pretrained on 
% an unlisted image database.
%
% No downloads are required to use this feature function, it is a part of 
% MATLAB's Image Processing Toolbox (introduced in R2017b).
% URL: (https://www.mathworks.com/help/images/ref/brisque.html).
% 
% SYNTAX & SEMANTICS
%   See 'calculate_NRpars' for interface specifications.
%

switch mode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% overall name of this group of NR features
case 'group'
    data = 'brisque';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR feature names
case 'feature_names'

    data{1} = 'brisque_score';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create NR parameter names (mean over time)
case 'parameter_names'

    data{1} = 'brisque_MEAN';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% color space
case 'luma_only'

    data = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate features on 1 frame
case 'read_mode'
    
    data = 'si';

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 'pixels'
    
    img = varargin{2};
    
    img = round(255*im2double(img));
    
    %Default model has following properties:
    % Alpha: [593x1 double] (593 support vectors)
    % Bias: 43.4582
    % SupportVectors: [593x36 double] 
    % Kernel: 'gaussian'
    % Scale: 0.3210
    model = brisqueModel();
    
    data{1} = model.calculateBRISQUEscore(img);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 'pars'
    
    % compute NR parameters
    feature_data = varargin{1,1};

    data(1) = nanmean(squeeze(feature_data{1}));
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
otherwise
    error('Mode not recognized. Aborting.');
end

end %of function

