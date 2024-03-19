function [data] = nrff_piqe(mode, varargin)

switch mode
    case 'group'
        data = 'piqe';
    case 'feature_names'
        data{1} = 'piqe_score';
    case 'parameter_names'
        data{1} = 'piqe_mean';
    case 'luma_only'
        data = true;
    case 'read_mode'
        data = 'si';
    case 'parallelization'
        data = true; 
    case 'pixels'
        y = varargin{2}; %give grayscale since the algorithm will convert to grayscale regardless
        score = piqe(y); 
        data{1,1} = score;
    case 'pars'
        feature_data = varargin{1,1};
        
        data(1) = nanmean(squeeze(feature_data{1}));
    otherwise
        error('Mode not recognized. Aborting.');
end