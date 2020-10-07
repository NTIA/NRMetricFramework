function compromise_NRpars(nr_dataset, base_dir, do_scaling, varargin)
% COMPROMISE
%   Visualize differences among parameter weights for multiple datasets, to
%   help find compromise weights for a linear model.
% SYNTAX
%   compromize_NRpars (nr_dataset, base_dir, do_scaling, ...
%       feature_function1, parameter1, ispos1, ...
%       feature_function2, parameter2, ispos2, ...
%       ... feature_functionN, parameterN, isposN); 
% SEMANTICS
%   "nr_dataset" = Data struction. Each describes an entire dataset (name, file location, ...)
%   "base_dir" = Path to directory where NR features and NR parameters are stored.
%   "do_scaling" = boolean. usually true, select false if parameters are
%   already on a [0..1] scale. 
%
%   The remaining input parameters are specified in triples, as follows:
%   "feature_function" = Function call to compute the feature. This no-reference 
%       feature function (NRFF) must adhere to the interface specified in 
%       calculate_NRpars.m.
%   "parameter1" = Number (offset) of the parameter to be examined.
%   "ispos" = true if the parameter is positively correlated to MOS,
%       meaning larger values indicate higher quality. "ispos" is false if 
%       the parameter is negatively correlated with MOS (i.e., lower values 
%       indicate higher quality).
%
%   All parameters will be scaled to [0..1] where 0=best, 1=worst
%   MOS are likewise scaled to [0..1] where 0=best, 1=worst
%
%   The goal is a linear model that can be expressed as 
%       yhat = 0 + w1*x1 + w2*x2 - ... +wN*xN
%   So that it can be easily converted into a linear model expressed as
%       yhat = 5 - w1'*x1 - w2'*x2 - ... -wN'*xN
%
%   Restriction: MOSs in all datasets must be scaled to [5..1] where
%   5=excellent and 1=bad

    % parse input arguments.
    cntP = 1;
    varargin_len = nargin-3;
    num_pars = varargin_len / 3;
    
    if mod(varargin_len,3)
        error('input arguments must specify function + parameter number + ispos triples');
    end


    min_mos = 1;
    max_mos = 5;
    % organize dataset information
    for cntD=1:length(nr_dataset)
        data(cntD).test = nr_dataset(cntD).test;
        data(cntD).subset = [nr_dataset(cntD).media(:).category2] == categorical({'train'});
        data(cntD).mos = [nr_dataset(cntD).media( data(cntD).subset ).mos];
        
        max_mos = max(max_mos,max(data(cntD).mos));
        min_mos = min(min_mos,min(data(cntD).mos));
        
        if max_mos > 5.5 || min_mos < 0.5 || sum(isnan(data(cntD).mos)) > 0  || sum(isinf(data(cntD).mos)) > 0
            error('Function compromise_NRpars requires all dataset MOSs to be defined on the scale [5..1]; check dataset %s', nr_dataset(cntD).test); 
        end 
    end
    
    % scale MOSs from [5..1] to [0..1]
    % if some values fall slightly outside the [5..1] range, pull them in
    % to [0..1] limits
    for cntD=1:length(nr_dataset)
        data(cntD).mos = 1 - (data(cntD).mos - min_mos) / (max_mos - min_mos);
    end
    
    fprintf('Loading data. Please wait a minute\n');
    fprintf('- this may take hours if data is not already computed\n\n');
    
    loop = 1;
    cntP = 1;
    while loop <= varargin_len
        % identify this parameter
        parinfo(cntP).feature_function = varargin{loop};
        
        parinfo(cntP).parnum = varargin{loop+1};        
        if ~isnumeric(parinfo(cntP).parnum)
            error('input argument specifying %dth parameter invalid: specify parameter number', cntP);
        end
        
        parinfo(cntP).ispos = varargin{loop+2};
        
        % load parameter data for all datasets
        for cntD = 1:length(data)
            % load all parameters for this dataset
            NRpars = calculate_NRpars(nr_dataset(cntD), base_dir, 'none', parinfo(cntP).feature_function);
            
            % figure parameter offset 
            if parinfo(cntP).parnum < 1 || parinfo(cntP).parnum > length(NRpars.par_name)
                error('Requested parameter number does not exist for parameter group %s dataset %s', parinfo(cntP).feature_function('group'), parinfo(cntP).parnum, data(cntD).test);
            end
            
            % record parameter data for later
            data(cntD).parvalue(cntP,:) = NRpars.data( parinfo(cntP).parnum, data(cntD).subset);
            parinfo(cntP).parname = NRpars.par_name{ parinfo(cntP).parnum };
        end
        
        loop = loop + 3;
        cntP = cntP + 1;
    end
    
    num_pars = length(parinfo);
    
    % Scale each parameter. Record scaling factors.
    if do_scaling
        for cntP = 1:num_pars
            min_value = inf;
            max_value = -inf;
            for cntD = 1:length(data)
                min_value = min(min_value,min(data(cntD).parvalue(cntP,:)));
                max_value = max(max_value,max(data(cntD).parvalue(cntP,:)));
            end
            % round these values
            if (max_value - min_value) <= 1
                min_value = floor(min_value*10) / 10;
                max_value = ceil(max_value*10) / 10;
            elseif (max_value - min_value) <= 10
                min_value = floor(min_value);
                max_value = ceil(max_value);
            else
                min_value = floor(min_value/10) * 10;
                max_value = ceil(max_value/10) * 10;
            end
        
            if parinfo(cntP).ispos
                parinfo(cntP).scale_minus = min_value;
                parinfo(cntP).scale_divide = max_value - min_value;
            else
                parinfo(cntP).scale_minus = max_value;
                parinfo(cntP).scale_divide = min_value - max_value;
            end
        
            for cntD = 1:length(data)
                data(cntD).parvalue(cntP,:) = 1.0 - (data(cntD).parvalue(cntP,:) - parinfo(cntP).scale_minus) / parinfo(cntP).scale_divide;
            end
        end
    end
    
    % create 'pooled' dataset
    num_datasets = length(data) + 1;
    data(num_datasets).test = 'pooled';
    data(num_datasets).mos = [];
    data(num_datasets).parvalue = [];
    for cntD = 1:num_datasets
        data(num_datasets).mos = [data(num_datasets).mos data(cntD).mos];
        data(num_datasets).parvalue = [data(num_datasets).parvalue data(cntD).parvalue];
    end
    
    %---------------------------------------------------------------------
    % Figure out which, if any, media must be discarded, because one or
    % more parameters are nan or inf
    fprintf('Discard media with nan or inf parameter values\n');
    need_warning = false;
    for cntD = 1:num_datasets
        want = true(1,length(data(cntD).mos)); 
        for cntP = 1:size(data(cntD).parvalue,1)
            want = [want & ~isnan(data(cntD).parvalue(cntP,:)) & ~isinf(data(cntD).parvalue(cntP,:))];
        end
        keep = sum(want);
        discard = length(want) - keep;
        
        if keep == 0
            error('No media remain after discards');
        end
        
        data(cntD).parvalue = data(cntD).parvalue(:,want);
        data(cntD).mos = data(cntD).mos(1,want);
        if sum(want) < length(want)
            need_warning = true;
        end
        fprintf('%5d of %d media in %s\n', discard, keep + discard, data(cntD).test);
    end
    fprintf('\n');
    
    %---------------------------------------------------------------------
    % Analysis

    fprintf('Parameter List:\n');
    for cntP = 1:num_pars
        fprintf('%d  %s\n', cntP, parinfo(cntP).parname);
    end
    
    % create figure with the parameters in figure title, if only 2 pars
    % compared
    if num_pars == 2
        temp = sprintf('par1 = %s, par2 = %s', parinfo(1).parname, parinfo(2).parname);
        figure('Name', temp, 'NumberTitle','off');
    end
    
    fprintf('\n\nMOS scaled so 0 = best, 1 = worst\n');
    if do_scaling
        fprintf('\nparameter scaling factors (before metric) are as follows:\n');
        for cntP = 1:num_pars
            fprintf('1 - ((par %d) - %5.3f ) / %7.4f\n', cntP, parinfo(cntP).scale_minus, parinfo(cntP).scale_divide); 
        end
    else
        fprintf('\nparameters NOT scaled. Assume already on [0..1] scale\n');
    end

    
    % cross correlation between parameters
    fprintf('\nParameter to parameter correlations, pooled data\n');
    fprintf('   ');
    for cntP = 1:num_pars
        fprintf(' %d    ', cntP);
    end
    fprintf('\n');
    
    for cntP = 1:num_pars
        fprintf('%d  ', cntP);
        
        for cntP2 = 1:num_pars
            tmp = corr(data(num_datasets).parvalue(cntP,:)', ...
                data(num_datasets).parvalue(cntP2,:)');
            fprintf('%5.2f ', tmp);
            
        end
        fprintf('\n');
    end
    fprintf('\n');
    
    % loop through each parameter. Find correlation between this parameter and each dataset..
    fprintf('Parameter to dataset correlations\n');
    fprintf('                      ');
    for cntP = 1:num_pars
        fprintf(' %d     ', cntP);
    end
    fprintf('\n');
    for cntD = 1:num_datasets
        fprintf('%20s  ', data(cntD).test);
        
        for cntP = 1:num_pars
            data(cntD).corr(cntP) = corr(data(cntD).mos', data(cntD).parvalue(cntP,:)');
            fprintf('%6.3f ', data(cntD).corr(cntP));
        end
        fprintf('\n');
    end
    fprintf('\n');
    
    
    % build a linear model for each dataset.
    fprintf('\nLinear metric weights and performance, when trained separately on each dataset\n');
    warning('off','MATLAB:rankDeficientMatrix');
    for cntD = 1:num_datasets
        % build model for each dataset
        y = data(cntD).mos';
        x = ones(length(y), num_pars+1);
        
        for cntP = 1:num_pars
            x(:,cntP) = ( data(cntD).parvalue(cntP,:) )';
        end

        data(cntD).weights = x\y;
        
        fprintf('%20s  ', data(cntD).test);
        for cntP = 1:num_pars
            fprintf('%6.2f * par%d +', data(cntD).weights(cntP), cntP);
        end
        fprintf('%6.2f', data(cntD).weights(num_pars+1));
        
        tmp = corr(y, x * data(cntD).weights); 
        fprintf('  (%6.3f correlation)\n', tmp);
    end
    warning('on','MATLAB:rankDeficientMatrix');
    
    if num_pars ~= 2
        fprintf('\nSkipping weighted compromise; this analysis requires exactly two parameters\n');
    else
        
        fprintf('\nSee figure for weighted compromise\n');
        points = 0:0.1:1;
        num_points = length(points);
        for cntD = 1:num_datasets
            y = data(cntD).mos';
            x = ones(length(y), num_pars+1);
            for cntP = 1:num_pars
                x(:,cntP) = ( data(cntD).parvalue(cntP,:) )';
            end
            
            for loop = 1:num_points
                wt1 = points(loop);
                wt2 = 1 - wt1;
                yhat = x * [wt2 wt1 0]';
                tmp = corrcoef(yhat, data(cntD).mos);
                value(loop) = tmp(1,2);
            end
            
            if cntD == 1
                plot(points, value, 'LineWidth', 1);
                title('linear model where par1 weight + par2 weight = 1');
                xlabel('par2 weight');
                ylabel('correlation');
            elseif cntD == num_datasets
                hold on;
                plot(points, value, 'k', 'LineWidth', 3);
                hold off;
            else
                hold on;
                plot(points, value, 'LineWidth', 1);
                hold off;
            end
            
            legend_labels{cntD} = data(cntD).test;
        end
        legend(legend_labels, 'location','eastoutside');
    end
    
    
    if need_warning
        fprintf('\nWARNING: these analyses omit media with NaN or INF parameter values\n');
    end
    
end
