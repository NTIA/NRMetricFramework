function ci_NRpars(nr_dataset, base_dir, feature_function)
% ci_NRpars
%   Estimate the confidence interval (CI) of an NR parameter
% SYNTAX
%   ci_NRpars(nr_dataset, base_dir, feature_function, parnum);
% SEMANTICS
%   Estimate the confidence interval (CI) of an NR metric or parameter, 
%   when compared to subjective test MOSs, using the classification of 
%   decisions reached by the subjective data and the metric for pairs of
%   stimuli (i.e., better, equivalent, or worse). The likelihood of each
%   combination will be plotted, and a suggested threshold returned.
%
% Input Parameters:
%   nr_dataset          Data structures, of datasets to be analyzed. If 2+
%                       datasets are provided, then the datasets will be
%                       weighted equally.
%   base_dir    Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature functions (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%
%   Details of this algorithm will be published in an NTIA Report. 
%   Analysis of subjective tests yields three constants that are used by
%   this function:
%   - confidence interval for MOSs: 0.5
%   - rate of uncertain = 1% (i.e., one test ranks the stimuli, the other
%                                   concludes equivalent quality)
%   - rate of disagreement = 20% (i.e., opposite ranking of the stimuli) 


    threshold_level = 0.5;
    false_rank_thresh = 0.01;
    false_diff_thresh = 0.10; % half of the uncertain rate of 20% 
    practical_threshold = 0.16;
    
    % load the parameters. This will calculate them, if not yet computed. 
    fprintf('Loading NR parameters. This will be very slow, if not yet calculated\n');
    for dcnt = 1:length(nr_dataset)
        % load parameter data
        NRpars(dcnt) = calculate_NRpars(nr_dataset(dcnt), base_dir, 'none', feature_function);        

        % find subset of training clips for each dataset 
        yesno = [nr_dataset(dcnt).media(:).category2] == categorical({'train'});
        offsets = 1:length(nr_dataset(dcnt).media);
        subset{dcnt} = offsets(yesno);
    end
    fprintf('NR parameters loaded\n\n');

    fprintf('*************************************************************\n');
    fprintf('NRFF Group %s\n\n', feature_function('group'));

    % analyze each parameter in turn
    for pcnt = 1:length(NRpars(1).par_name)
        
        fprintf('--------------------------------------------------------------\n');
        fprintf('%d) %s\n\n', pcnt, NRpars(1).par_name{pcnt});

        % calculate range of this parameter
        this_par = [];
        for dcnt = 1:length(nr_dataset)
            this_par = [this_par [NRpars(dcnt).data(pcnt,subset{dcnt})]];
            tmp = corrcoef([NRpars(dcnt).data(pcnt,subset{dcnt})], [nr_dataset(dcnt).media(subset{dcnt}).mos]);
            if tmp(1,2) >= 0
                pos_corr(dcnt) = 1;
            else
                pos_corr(dcnt) = -1;
            end
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
            fprintf('Error: parameter has a constant value\n');
            continue;
        end

        % clear variables from last loop
        clear subj obj wt;
        
        curr = 1;
        for dcnt = 1:length(nr_dataset)
            for mcnt1 = 1:length(subset{dcnt})
                for mcnt2 = mcnt1+1:length(subset{dcnt})
                    want1 = subset{dcnt}(mcnt1);
                    want2 = subset{dcnt}(mcnt2);

                    % subj(curr) is decision whether #1 is better,
                    % equivalent, or worse than #2
                    diff = nr_dataset(dcnt).media(want1).mos - nr_dataset(dcnt).media(want2).mos;
                    if diff > threshold_level
                        subj(curr) = 1;
                    elseif diff < -threshold_level
                        subj(curr) = -1;
                    else
                        subj(curr) = 0;
                    end

                    % obj(curr) is distance before thresholding, since the
                    % point of this function is to ideal_ci a threshold
                    obj(curr) = NRpars(dcnt).data(pcnt,want1) - NRpars(dcnt).data(pcnt,want2); 
                    
                    % note weight 
                    wt(curr) = 1 / length(nr_dataset(dcnt).media);

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
        % round our increment to two significant digits
        incr = round((pmax-pmin)/100, 2, 'significant');
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
            continue;
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
        fprintf('%4.3f Ideal CI      (%d %% false ranking, %d %% false distinction, %d %% correct ranking)\n', ...
            list_want(ideal_ci), round(false_ranking(ideal_ci)*100), round(false_distinction(ideal_ci)*100), round(correct_rank(ideal_ci)*100));
        fprintf('%4.3f Practical CI  (%d %% false ranking, %d %% false distinction, %d %% correct ranking)\n', ...
            list_want(practical_ci), round(false_ranking(practical_ci)*100), round(false_distinction(practical_ci)*100), round(correct_rank(practical_ci)*100));

        % dataset names
        tmp = '';
        for dcnt = 1:length(nr_dataset)
            tmp = [tmp ' ' nr_dataset(dcnt).test];
        end
        
        % create plot
        figure('name', tmp); % put dataset names on title bar
        plot(list_want, 100 * correct_rank, 'g', 'linewidth', 2);
        hold on;
        plot(list_want, 100 * correct_tie, '-', 'linewidth', 2, 'color', [1 0.9 0]);
        plot(list_want, 100 * false_tie, '--', 'linewidth', 2, 'color', [1 0.9 0]);
        plot(list_want, 100 * false_distinction, '--', 'linewidth', 2, 'color', [0.3 0.3 1]);
        plot(list_want, 100 * false_ranking, 'r', 'linewidth', 2);

        curr_axis = axis;
        plot([list_want(ideal_ci) list_want(ideal_ci)], ylim, ':k', 'linewidth', 1.5);
        plot([list_want(practical_ci) list_want(practical_ci)], ylim, ':k', 'linewidth', 1);
        axis(curr_axis);
        hold off;

        xlabel(['$\Delta$ Metric (' NRpars(1).par_name{pcnt} ')'], 'interpreter','latex')
        ylabel('Probability', 'interpreter','latex')
        grid on;

        tmp = yticks;
        for cnt=1:length(tmp)
            tmpl{cnt} = sprintf('%2d%%', tmp(cnt));
        end
        yticklabels(tmpl)

        legend('Correct ranking', 'Correct tie', 'False tie', 'False distinction', ...
            'False ranking', 'Ideal CI', 'Practical CI', 'location', 'eastoutside', ...
            'interpreter','latex');

    end
    
    
end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
