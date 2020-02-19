function analyze_NRpars(nr_dataset, base_dir, feature_function, varargin)
% analyze_NRpars
%   Analyze the NR parameters, calculated by one or more NRFF functions,
%   against one or more dataset
% SYNTAX
%   analyze_NRpars(nr_dataset, base_dir, feature_function);
%   analyze_NRpars(...,'clip',value);
% SEMANTICS
%   Analyze the metrics associated with one NR parameter group. 
%   This analysis intentionally omits verification stimuli.
%
% Input Parameters:
%   nr_dataset          Data struction. Each describes an entire dataset (name, file location, ...)
%   base_dir    Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature functions (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%
%   Optional parameters. Some options contradict others.
%
%   'clip',         Lower, upper, = clip the parameter values to lie between [lower..upper]  
%   'sqrt'          Square root parameter values before analysis
%   'square'        Square parameter values before analysis
%
%   'allcategory', N, Merge all datasets together, then split by category.
%                   Limited to category 1, 3, or 4. 
%   'category', N,  Split each parameter & dataset by category number N.
%                   Categories definitions are unique for each dataset 
%                   Category 2 cannot be selected, this analysis is
%                   inherently part of the training process. 
%                   nr_dataset must contain only one dataset.
%   'info',         List category options for the dataset(s) but don't analyze.
%   'outlier',      List the worst outliers
%   'par', N,       Only analyze the Nth parameter (identified by number)
%   'plot'          Create scatter plots

    do_clip = false;
    do_sqrt = false;
    do_square = false;
    do_plot = false;
    do_print = true;
    do_parnum = inf; % all by default
    do_category = nan;
    do_outlier = false;
    do_merge = false;
    
    preproc_message = '';

    cnt = 1;
    varargin_len = nargin-3;
    while cnt <= varargin_len
        if strcmpi(varargin{cnt},'clip') && cnt + 2 <= varargin_len
            do_clip = true;
            clip_lower = varargin{cnt+1};
            clip_upper = varargin{cnt+2};
            cnt = cnt + 3;
            
            preproc_message = [preproc_message sprintf(' clip [%4.2f..%4.2f]', clip_lower, clip_upper)];
        elseif strcmpi(varargin{cnt},'par') && cnt + 1 <= varargin_len
            do_parnum = varargin{cnt+1};
            cnt = cnt + 2;
        elseif strcmpi(varargin{cnt},'sqrt')
            do_sqrt = true;
            cnt = cnt + 1;
            preproc_message = [preproc_message ' square root'];
        elseif strcmpi(varargin{cnt},'square')
            do_square = true;
            cnt = cnt + 1;
            preproc_message = [preproc_message ' square'];
        elseif strcmpi(varargin{cnt},'plot')
            do_plot = true;
            cnt = cnt + 1;
        elseif strcmpi(varargin{cnt},'outlier')
            do_outlier = true;
            cnt = cnt + 1;
        elseif strcmpi(varargin{cnt},'category') && cnt + 1 <=varargin_len
            do_category = varargin{cnt+1};
            if ~isnumeric(do_category) || do_category < 1 || do_category == 2 || do_category > 8
                error('Category must be [1..8] but not 2');
            end
            if length(nr_dataset) > 1
                error('Category option only available when analyze_NRpars is given one dataset');
            end
            cnt = cnt + 2;
        elseif strcmpi(varargin{cnt},'allcategory') && cnt+1 <= varargin_len
            do_category = varargin{cnt+1};
            if ~isnumeric(do_category) || do_category < 1 || do_category == 2 || do_category > 4
                error('Category must be 1, 3, or 4 (identical for all datasets)');
            end
            if length(nr_dataset) < 1
                error('AllCategory option only available when analyze_NRpars is given two or more datasets');
            end
            do_merge = true;
            cnt = cnt + 2;
            
        elseif strcmpi(varargin{cnt},'info')
            fprintf('\nAvailable categories for analysis:\n');
            for dcnt = 1:length(nr_dataset)
                fprintf('Dataset %s\n', nr_dataset(dcnt).test);
                options = unique([nr_dataset(dcnt).media(:).category1]);
                options = options(~isundefined(options));
                if length(options) > 1
                    fprintf('- Category 1 - ');
                    for ocnt = 1:length(options)
                        fprintf('%s ', char(options(ocnt)));
                    end
                    fprintf('\n');
                end
                options = unique([nr_dataset(dcnt).media(:).category3]);
                options = options(~isundefined(options));
                if length(options) > 1
                    fprintf('- Category 3 - ');
                    for ocnt = 1:length(options)
                        fprintf('%s ', char(options(ocnt)));
                    end
                    fprintf('\n');
                end
                options = unique([nr_dataset(dcnt).media(:).category4]);
                options = options(~isundefined(options));
                if length(options) > 1
                    fprintf('- Category 4 - ');
                    for ocnt = 1:length(options)
                        fprintf('%s ', char(options(ocnt)));
                    end
                    fprintf('\n');
                end
                options = unique([nr_dataset(dcnt).media(:).category5]);
                options = options(~isundefined(options));
                if length(options) > 1
                    fprintf('- Category 5 - ');
                    for ocnt = 1:length(options)
                        fprintf('%s ', char(options(ocnt)));
                    end
                    fprintf('\n');
                end
                options = unique([nr_dataset(dcnt).media(:).category6]);
                options = options(~isundefined(options));
                if length(options) > 1
                    fprintf('- Category 6 - ');
                    for ocnt = 1:length(options)
                        fprintf('%s ', char(options(ocnt)));
                    end
                    fprintf('\n');
                end
                options = unique([nr_dataset(dcnt).media(:).category7]);
                options = options(~isundefined(options));
                if length(options) > 1
                    fprintf('- Category 7 - ');
                    for ocnt = 1:length(options)
                        fprintf('%s ', char(options(ocnt)));
                    end
                    fprintf('\n');
                end
                options = unique([nr_dataset(dcnt).media(:).category8]);
                options = options(~isundefined(options));
                if length(options) > 1
                    fprintf('- Category 8 - ');
                    for ocnt = 1:length(options)
                        fprintf('%s ', char(options(ocnt)));
                    end
                    fprintf('\n');
                end
            end
            return;
        else
            error('optional input argument %s not recognized or not formatted correctly', char(varargin{cnt}));
        end
    end

    % load the parameters. This will calculate them, if not yet computed. 
    fprintf('Loading NR parameters. This will be very slow, if not yet calculated\n');
    for dcnt = 1:length(nr_dataset)
        NRpars(dcnt) = calculate_NRpars(nr_dataset(dcnt), base_dir, 'none', feature_function);
        
        if do_square
            NRpars(dcnt).data = (NRpars(dcnt).data).^2;
        end
        if do_sqrt
            NRpars(dcnt).data = sqrt(NRpars(dcnt).data);
        end
        if do_clip
            for pcnt = 1:size(NRpars(dcnt).data,1)
                NRpars(dcnt).data(pcnt,:) = min( NRpars(dcnt).data(pcnt,:), clip_upper);
                NRpars(dcnt).data(pcnt,:) = max( NRpars(dcnt).data(pcnt,:), clip_lower);
            end
        end
    end
    fprintf('NR parameters loaded\n\n');


    if do_merge
        % merge datasets
        all_datasets = nr_dataset(1);
        for dcnt=2:length(nr_dataset)
            all_datasets.media = [all_datasets.media nr_dataset(dcnt).media];
        end
        all_datasets.test = 'merged';
        all_datasets.path = '';

        nr_dataset = all_datasets;
        
        % merge parameters. Only merge useful information.
        all_NRpars = NRpars(1);
        all_NRpars.test = 'merged';
        for dcnt = 2:length(NRpars)
            all_NRpars.media_name = [all_NRpars.media_name NRpars(dcnt).media_name ];
            all_NRpars.data = [all_NRpars.data NRpars(dcnt).data ];
        end
        
        NRpars = all_NRpars;
    end
    
    %
    fprintf('*************************************************************\n');
    fprintf('NRFF Group %s\n\n', feature_function('group'));

    if isinf(do_parnum)
        want_min = 1;
        want_max = length(NRpars(1).par_name);
    else
        want_min = do_parnum;
        want_max = do_parnum;
        if do_parnum > length(NRpars(1).par_name) || do_parnum < 1
            error('Requested a parameter number that does not exist');
        end
    end
    % loop through each parameter and dataset
    for pcnt = want_min:want_max
        % combine datasets
        all_datasets = nr_dataset(1);
        all_datasets.test = 'pooled';
        NRpars_all = NRpars(1);
        for dcnt = 2:length(nr_dataset)
            all_datasets.media = [all_datasets.media nr_dataset(dcnt).media];
            NRpars_all.data = [NRpars_all.data NRpars(dcnt).data];
        end

        fprintf('--------------------------------------------------------------\n');
        fprintf('%d) %s %s\n', pcnt, NRpars(1).par_name{pcnt}, preproc_message);
        if do_plot && length(nr_dataset) > 1
            do_subplot = true;
            figure('Name', NRpars(1).par_name{pcnt});
            subnum = ceil(length(nr_dataset) / 3); 
            for dcnt = 1:length(nr_dataset)
                subplot(3, subnum, dcnt);
                [corr(dcnt), rmse(dcnt)] = analyze_par_dataset(nr_dataset(dcnt), NRpars(dcnt), pcnt, do_print, do_plot, do_subplot, false, all_datasets, NRpars_all, 2, nan, preproc_message);
            end
        else
            do_subplot = false;
            for dcnt = 1:length(nr_dataset)
                [corr(dcnt), rmse(dcnt)] = analyze_par_dataset(nr_dataset(dcnt), NRpars(dcnt), pcnt, do_print, do_plot, do_subplot, false, all_datasets, NRpars_all, 2, nan, preproc_message);
            end
        end

        % combined
        fprintf('\n'); 
        fprintf('average          corr = %5.2f  rmse = %5.2f\n', mean(corr), mean(rmse));
        if length(nr_dataset) ~= 1
            do_subplot = false;
            analyze_par_dataset(all_datasets, NRpars_all, pcnt, do_print, do_plot, do_subplot, false, all_datasets, NRpars_all, 2, nan, preproc_message);
            fprintf('\n\n');
        end
        
        if ~isnan(do_category)
            fprintf('\n\n');
            fprintf('Analyze by %s\n\n', nr_dataset.category_name{do_category});
            options = nr_dataset.category_list{do_category};
            if do_plot && length(options) > 1
                do_subplot = true;
                figure('Name', NRpars(1).par_name{pcnt});
                subnum = ceil(length(options) / 3); 
                for ccnt = 1:length(options)
                    subplot(3, subnum, ccnt);
                    analyze_par_dataset(nr_dataset, NRpars, pcnt, do_print, do_plot, do_subplot, false, all_datasets, NRpars_all, do_category, options(ccnt), preproc_message);
                end
            else
                do_subplot = false;
                for ccnt = 1:length(options)
                    analyze_par_dataset(nr_dataset, NRpars, pcnt, do_print, do_plot, do_subplot, false, all_datasets, NRpars_all, do_category, options(ccnt), preproc_message);
                end
            end
        end
               
    end

    
    % loop through each parameter and dataset a second time, to list
    % outliers.
    if do_outlier
        fprintf('\n\n\n\n');
        for pcnt = want_min:want_max

            fprintf('--------------------------------------------------------------\n');
            fprintf('Outliers\n\n');
            fprintf('%d) %s %s\n', pcnt, NRpars(1).par_name{pcnt}, preproc_message);
            for dcnt = 1:length(nr_dataset)
                analyze_par_dataset(nr_dataset(dcnt), NRpars(dcnt), pcnt, false, false, false, true, all_datasets, NRpars_all, 2, nan, preproc_message);
            end
 
            if ~isnan(do_category)
                options = nr_dataset.category_list{do_category};
                for ccnt = 1:length(options)
                    fprintf('\n\n');
                    fprintf('Outliers by %s = %s\n\n', nr_dataset.category_name{do_category}, options(ccnt));
                    analyze_par_dataset(nr_dataset, NRpars, pcnt, ...
                        false, false, false, true, all_datasets, NRpars_all, do_category, options(ccnt), preproc_message);
                end
            end

        end
    end
end


function [corr, rmse] = analyze_par_dataset(one_dataset, one_NRpars, pcnt, do_print, do_plot, do_subplot, do_outliers, ...
    all_dataset, all_NRpars, is_category, is_level, preproc_message)

    % pick off training media for this parameter and dataset
    subset = [one_dataset.media(:).category2] == categorical({'train'});
    switch is_category
        case 1
            subset = subset & [one_dataset.media(:).category1] == is_level;
            test_name = is_level;
        case 2
            test_name = one_dataset.test;
        case 3
            subset = subset & [one_dataset.media(:).category3] == is_level;
            test_name = is_level;
        case 4
            subset = subset & [one_dataset.media(:).category4] == is_level;
            test_name = is_level;
        case 5
            subset = subset & [one_dataset.media(:).category5] == is_level;
            test_name = is_level;
        case 6
            subset = subset & [one_dataset.media(:).category6] == is_level;
            test_name = is_level;
        case 7
            subset = subset & [one_dataset.media(:).category7] == is_level;
            test_name = is_level;
        case 8
            subset = subset & [one_dataset.media(:).category8] == is_level;
            test_name = is_level;
    end
    
    % skip if less than 2 elements
    if sum(double(subset)) < 2
        xlabel(one_NRpars.par_name{pcnt},'interpreter','none');
        ylabel('MOS', 'interpreter','none');
        title(sprintf('%s (no data)', test_name), 'interpreter','none');
        return;
    end

    % organize data for linear regression
    xdata = ones(sum(subset),2);
    xdata(:,2) = one_NRpars.data(pcnt,subset);
    ydata = [one_dataset.media(subset).mos]';
    
    % discard inf, nan
    keep = isfinite(xdata(:,2)) & isfinite(ydata);
    xdata = xdata(keep,:);
    ydata = ydata(keep);
    
    % linear regression, with default if not possible
    if max([one_NRpars.data(pcnt,subset)]) == min([one_NRpars.data(pcnt,subset)]) 
        w = [0 0]';
    else
        w = xdata \ ydata;
    end
    

    if do_print
        [corr, rmse] = correlation_rmse(ydata, xdata * w, length(ydata)-2);
        values = sort(one_NRpars.data(pcnt,subset),'ascend');
        offset = max(1, round([0 0.25 0.5 0.75 1] * length(values)));
        values = values(offset);
        fprintf('%-15s  corr = %5.2f  rmse = %5.2f  percentiles [%5.2f,%5.2f,%5.2f,%5.2f,%5.2f]\n', test_name, ...
            corr, rmse, values(1), values(2), values(3), values(4), values(5)); 
    end

    if do_plot
        if ~do_subplot
            figure('Name', one_NRpars.par_name{pcnt});
        end
        
        train_set_all = [all_dataset.media(:).category2] == categorical({'train'});
        plot(all_NRpars.data(pcnt,train_set_all), [all_dataset.media(train_set_all).mos], '.', 'MarkerSize', 3, 'Color',[0 0.8 0]);
        hold on;

        % If plotting a sub-set of data, overlay subset in blue
        if length([one_dataset.media(subset).mos]) < length([all_dataset.media(train_set_all).mos])
            plot(one_NRpars.data(pcnt,subset), [one_dataset.media(subset).mos], '.b', 'MarkerSize', 6);
        else
            % otherwise, just make data points larger and retain green color.
            plot(one_NRpars.data(pcnt,subset), [one_dataset.media(subset).mos], '.', 'MarkerSize', 6, 'Color', [0 0.8 0]);
        end

        % plot linear fit
        xmin = min(one_NRpars.data(pcnt,subset));
        xmax = max(one_NRpars.data(pcnt,subset));
        ymin = w(1) + w(2) * xmin;
        ymax = w(1) + w(2) * xmax;
        plot([xmin xmax],[ymin,ymax],'r-','LineWidth',1);

        hold off;
        
        % specify axes. Always include 0 in metric value range. Assume
        % [1..5] for MOS range.
        xmin = min(min(all_NRpars.data(pcnt,train_set_all)),min(one_NRpars.data(pcnt,subset)));
        xmax = max(max(all_NRpars.data(pcnt,train_set_all)),max(one_NRpars.data(pcnt,subset)));
        if xmin > 0
            xmin = 0;
        elseif xmax < 0
            xmax = 0;
        end
        
        ymin = min(min([all_dataset.media(train_set_all).mos]), min([one_dataset.media(subset).mos]));
        ymin = min(ymin, 1);
        ymax = max(max([all_dataset.media(train_set_all).mos]), max([one_dataset.media(subset).mos]));
        ymax = max(ymax, 5);
        
        axis([xmin xmax ymin ymax]);
        
        % labels
        if isempty(preproc_message) 
            xlabel(one_NRpars.par_name{pcnt},'interpreter','none');
        else
            xlabel([one_NRpars.par_name{pcnt} preproc_message],'interpreter','none');
        end
        ylabel('MOS', 'interpreter','none');
        title(sprintf('%s, y = %4.2f + %4.2f * x', test_name, w(1), w(2)), 'interpreter','none');
    end
    
    if do_outliers
        residuals = (w(1) + w(2) * one_NRpars.data(pcnt,subset)) - [one_dataset.media(subset).mos];
        [~,order] = sort(residuals,'descend');
        len = length(residuals);
        want = min(10,0.1 * len);
        tmp = 1:length(one_dataset.media);
        subsetnum = tmp(subset);
        for cnt=[1:want (len-want+1):len]
            num = subsetnum(order(cnt));
            fprintf(' mos %4.2f  par %6.3f  stimuli %d = %s\n', one_dataset.media((num)).mos, ...
                one_NRpars.data(pcnt,(num)), (num), one_dataset.media((num)).file);
        end
    end
    
end


function [corr, rmse] = correlation_rmse(mos, yhat, len_minus_df)
% CORRELATION_RMSE
%   Compute correlation, RMSE
% SYNTAX
%   [corr, rmse] = ...
%       correlation_rmse(mos, yhat, len_minus_df)
% DESCRIPTION
%   'mos' is a 1-D array holding MOS or DMOS
%   'yhat' is the predicted MOS, a 1-D array like 'mos'
%   'len_minus_df' is the length of 'mos', 'std', and 'yhat', minus the
%               degrees of freedom used in the 'yhat' fitting.  Adjust this
%               by any averaging performed (e.g., HRC averaging).
%   Returns the following:
%   'corr' is the correlation between 'mos' and 'yhat'
%   'rmse' is the root mean square error between 'mos' and 'yhat'


    % compute correlation, and place that into variable ‘corr’
    temp = corrcoef(yhat, mos);
    corr = temp(1,2);

    % compute RMSE, and place that into variable ‘rmse’
    rmse = sqrt(sum((yhat - mos).^2) / len_minus_df );
    
    if isnan(corr)
        rmse = inf;
    end

    %  When computing on a per-HRC basis, the above equations remain the same but
    %  the definitions of the variables change slightly.  ‘len_minus_df’ must be
    %  divided by the number of SRC averaged (e.g., 8 for VQEG MM).
    %  Also, the number of viewers increases by the number of SRC averaged.  This
    %  also changes the 2.069 multiplier constant to 1.96 in the equation for temp.
end
