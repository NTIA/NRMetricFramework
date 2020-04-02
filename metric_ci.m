function [ideal_ci, practical_ci] = metric_ci(metric_name, num_datasets, dataset_names, dataset_mos, dataset_metrics)
% metric_ci
%   Estimate the confidence interval (CI) of an NR parameter
% SYNTAX
%   [ideal_ci, practical_ci] = metric_ci(metric_name, num_datasets, dataset_names, dataset_mos, dataset_metrics);
% SEMANTICS
%   Estimate the confidence interval (CI) of an NR metric or parameter, 
%   by comparing the conclusions reached by the model with conclusions 
%   reached by a subjective test. Both will use a constant confidence 
%   interval (CI) to make decisions. The subjective CI is based on
%   5-level ACR MOSs. Two recommended CIs are printed to the command window.
%   (1) ideal CI, and (2) practical CI. The classification types are plotted, 
%   which allows the user to choose an alternate CI.
%
% Input Parameters:
%   metric_name     Character string that contains the metric's name
%   num_datasets    Number of subjective datasets
%   dataset_names   Cell array. For each dataset (1..num_datasets), a
%                   character array that contains the name of this dataset.
%   dataset_mos     Cell array. For each dataset (1..num_datasets), a
%                   double array that contains the mean opinion score (MOS)
%                   for each stimuli in the dataset.
%   dataset_metrics Cell array. For each dataset (1..num_datasets), a
%                   double array that contains the metric's value for each
%                   stimuli in the dataset. Order of stimuli must be
%                   identical to dataset_mos.
%
%   Details of this algorithm are pending publication. 
%
% Constraints:
%   All datasets are weighted equally.
%   The MOSs must range from 1 to 5. 


    % Analysis of subjective tests yields several constants that are used by
    % this function. These constants are computed from lab-to-lab comparisons
    % of subjective tests.   
    threshold_level = 0.5; % delta S, where 95% of stimuli MOS can be rank orderd
    false_rank_thresh = 0.01; % disagree rate
    false_diff_thresh = 0.10; % half of the uncertain rate of 20% 
    practical_threshold = 0.16; % half of maximum unceretain rate plus disagree rate
    
    fprintf('Metric confidence interval analysis for %s\n\n', metric_name);

    % calculate range of this parameter
    this_par = [];
    pos_corr = nan(1,num_datasets);
    for dcnt = 1:num_datasets
        tmp = corrcoef(dataset_mos{dcnt}, dataset_metrics{dcnt});
        if tmp(1,2) >= 0
            pos_corr(dcnt) = 1;
        else
            pos_corr(dcnt) = -1;
        end
        this_par = [ this_par dataset_metrics{dcnt} ];
    end

    this_par = sort(this_par);
    pmin = this_par(1);
    pmax = this_par(length(this_par));
    fprintf('Full range [%4.2f..%4.2f], ', pmin, pmax);
    fprintf('95%% of data in [%4.2f..%4.2f]\n', this_par(round(0.025*length(this_par))), this_par(round(0.975*length(this_par))));

    if sum(pos_corr) > 0
        fprintf('Positively correlated with MOS for most datasets\n\n');
        is_pos_corr = true;
    else
        fprintf('Negatively correlated with MOS for most datasets\n\n');
        is_pos_corr = false;
    end

    if pmin == pmax
        fprintf('Warning: parameter has a constant value, aborting.\n');
        return;
    end

    % manually loop through all pairs of stimuli
    curr = 1;
    for dcnt = 1:num_datasets
        curr_len = length(dataset_mos{dcnt});
        for mcnt1 = 1:curr_len
            for mcnt2 = mcnt1+1:curr_len

                % subj(curr) is decision whether #1 is better,
                % equivalent, or worse than #2
                diff = dataset_mos{dcnt}(mcnt1) - dataset_mos{dcnt}(mcnt2);
                if diff > threshold_level
                    subj(curr) = 1;
                elseif diff < -threshold_level
                    subj(curr) = -1;
                else
                    subj(curr) = 0;
                end

                % obj(curr) is distance before thresholding, since the
                % point of this function is to ideal_ci a threshold
                obj(curr) = dataset_metrics{dcnt}(mcnt1) - dataset_metrics{dcnt}(mcnt2); 

                % note weight 
                wt(curr) = 1 / length(dataset_mos{dcnt});

                curr = curr + 1;
            end
        end
    end
    % flip sign of objective differences, if parameter is
    % negatively correlated to MOS
    if ~is_pos_corr
        obj = -obj;
    end

    % Have all of the data. Now make the plot.
    % round our increment to one significant digits
    incr = round((pmax-pmin)/100, 1, 'significant');
    list_want = incr:incr:(pmax-pmin);

    correct_rank = zeros(1,length(list_want));
    correct_tie = zeros(1,length(list_want));
    false_ranking = zeros(1,length(list_want));
    false_distinction = zeros(1,length(list_want));
    false_tie = zeros(1,length(list_want));

    % create data for roughly 60% of the range of parameter values
    % from there, the plot flattens and contains no more info
    for loop = 1:length(list_want)
        delta = list_want(loop);
        for curr = 1:length(subj)
            if (subj(curr) == 1 && obj(curr) >= delta) || ...
                    (subj(curr) == -1 && obj(curr) <= -delta)
                correct_rank(loop) = correct_rank(loop) + wt(curr);
            elseif subj(curr) == 0 && obj(curr) > -delta && obj(curr) < delta
                correct_tie(loop) = correct_tie(loop) + wt(curr);
            elseif (subj(curr) == 1 && obj(curr) <= -delta) || ...
                    (subj(curr) == -1 && obj(curr) >= delta)
                false_ranking(loop) = false_ranking(loop) + wt(curr);
            elseif (subj(curr) ~= 0 && obj(curr) > -delta && obj(curr) < delta)
                false_tie(loop) = false_tie(loop) + wt(curr);
            else
                false_distinction(loop) = false_distinction(loop) + wt(curr);
            end
        end
    end
    total_votes = sum(wt);

    correct_rank = correct_rank / total_votes;
    correct_tie = correct_tie / total_votes;
    false_ranking = false_ranking / total_votes;
    false_distinction = false_distinction / total_votes;
    false_tie = false_tie / total_votes;

    % if too much data is false_tie and correct_tie at minimum
    % threshold, don't try. Skip. Rule of thumb: 50% ties. We expect
    % values close to zero, so this should mean most of the metric is a
    % constant value.
    if false_tie(1) + correct_tie(1) > 0.5
        fprintf('Half of data is correct ties or false ties. Skipping.\n');
        return;
    end

    % compute the ideal ci
    ideal_ci = find( false_ranking < false_rank_thresh & false_distinction < false_diff_thresh, 1 );
    if isempty(ideal_ci)
        ideal_ci = length(list_want);
    end

    % compute the practical CI
    practical_ci = find( false_ranking + false_distinction < practical_threshold, 1 );
    if isempty(practical_ci)
        practical_ci = length(list_want);
    end

    % print recommended threshold
    fprintf('%5.4f Ideal CI      (%d %% correct ranking, %d %% false ranking, %d %% false distinction, %d %% false tie, %d %% correct tie)\n', ...
        list_want(ideal_ci), round(correct_rank(ideal_ci)*100), round(false_ranking(ideal_ci)*100), round(false_distinction(ideal_ci)*100), ...
            round(false_tie(ideal_ci)*100), round(correct_tie(ideal_ci)*100));
    fprintf('%5.4f Practical CI  (%d %% correct ranking, %d %% false ranking, %d %% false distinction, %d %% false tie, %d %% correct tie)\n', ...
        list_want(practical_ci), round(correct_rank(practical_ci)*100), round(false_ranking(practical_ci)*100), round(false_distinction(practical_ci)*100), ...
            round(false_tie(practical_ci)*100), round(correct_tie(practical_ci)*100));

    % dataset names
    tmp = '';
    for dcnt = 1:num_datasets
        tmp = [tmp ' ' dataset_names{dcnt}];
    end

    % create plot
    figure('name', tmp); % put dataset names on title bar
    plot(list_want, 100 * correct_rank, 'g', 'linewidth', 2);
    hold on;
    plot(list_want, 100 * false_ranking, 'r', 'linewidth', 2);
    plot(list_want, 100 * false_distinction, '--', 'linewidth', 2, 'color', [0.3 0.3 1]);
    plot(list_want, 100 * false_tie, '--', 'linewidth', 2, 'color', [1 0.9 0]);
    plot(list_want, 100 * correct_tie, '-', 'linewidth', 2, 'color', [1 0.9 0]);

    curr_axis = axis;
    plot([list_want(ideal_ci) list_want(ideal_ci)], ylim, '-k', 'linewidth', 1);
    plot([list_want(practical_ci) list_want(practical_ci)], ylim, '-.k', 'linewidth', 1);
    curr_axis(2) = list_want(ideal_ci) * 1.25; % only graph 25% beyond the ideal CI
    axis(curr_axis);
    hold off;

    xlabel(['$\Delta$ Metric (' metric_name ')'], 'interpreter','latex')
    ylabel('Probability', 'interpreter','latex')
    grid on;

    tmp = yticks;
    for cnt=1:length(tmp)
        tmpl{cnt} = sprintf('%2d%%', tmp(cnt));
    end
    yticklabels(tmpl)

    legend('Correct ranking', 'False ranking', 'False distinction', 'False tie', ...
        'Correct tie', 'Ideal CI', 'Practical CI', 'location', 'eastoutside', ...
        'interpreter','latex');

    ideal_ci = list_want(ideal_ci);
    practical_ci = list_want(practical_ci);
end

