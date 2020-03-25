function classify_NRpars(nr_dataset, base_dir, feature_function)
% classify_NRpars
%   Classify the type of errors associated with the distance between NRpar values 
% SYNTAX
%   classify_NRpars(nr_dataset, base_dir, feature_function, parnum);
% SEMANTICS
%   The performance of an NR parameter is evaluated based on the
%   classification errors when compared to subjective data (i.e., false
%   differentiation, false ties, and false classification). 
%
% Input Parameters:
%   nr_dataset          Data struction. Each describes an entire dataset (name, file location, ...)
%   base_dir    Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature functions (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%
%  Details:
%   This function computes a variant of the classification plots specified
%   by ATIS T1.TR.72-2003 “Methodological Framework for Specifying Accuracy 
%   and Cross-Calibration of Video Quality Metrics,” available at 
%   https://www.atis.org/docstore/product.aspx?id=10518.
%   The following modifications are made:
%   1. Data from multiple datasets is included into a single analysis.
%   2. The subjective and objective data are not scaled
%   3. A constant threshold is used to compare subjective scores
%   Data points are only compared within a single dataset, but results from
%   multiple datasets are aggregated into the overall conclusion. Number of
%   subjects is not viewed as an accurate correction factor, because the
%   datasets include lab studies, field studies, and crowdsource studies.
%
%
%
% DEFINITIONS:
%
% Lab study refers to a subjetive test conducted in a controlled laboratory
% environment, with 24 subjects and a rigorous experiment design that adheres to
% best practices of VQEG and the ITU. Source scenes must be good quality or better.
% Confounding factors are minimized.
% 
% Field study refers to a subjective test that focuses on camera impairments
% and other problems from deployed systems. The experiment design contains
% contains confounding factors.
% 
% Informative study refers to subjective tests with less rigorous experiment designs,
% which may include fewer subjects, scenes selected for convenience, distracting
% test environments, new video technologies, and media that are difficult to
% rate (e.g., a subject may simultaneously want to rate the media both "good" and "poor".



    threshold_level = [0.5 0.7 1.0];
    threshold_name = {'Lab Study', 'Field Study', 'Informative Study'};
    
    
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
    fprintf('Subjective test confidence intervals are\n');
    for tcnt = 1:length(threshold_level)
        fprintf('    %4.1f for a %s\n', threshold_level(tcnt), threshold_name{tcnt});
    end
    fprintf('\n');
    
    
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

        for tcnt = 1:length(threshold_level)
            thresh = threshold_level(tcnt);

            curr = 1;
            for dcnt1 = 1:length(nr_dataset)
                for mcnt1 = 1:length(subset{dcnt})
                    for mcnt2 = mcnt1+1:length(subset{dcnt})
                        want1 = subset{dcnt}(mcnt1);
                        want2 = subset{dcnt}(mcnt2);

                        % subj(curr) is decision whether #1 is better,
                        % equivalent, or worse than #2
                        diff = nr_dataset(dcnt).media(want1).mos - nr_dataset(dcnt).media(want2).mos;
                        if diff > thresh
                            subj(curr) = 1;
                        elseif diff < -thresh
                            subj(curr) = -1;
                        else
                            subj(curr) = 0;
                        end

                        % obj(curr) is distance before thresholding, since the
                        % point of this function is to choose a threshold
                        obj(curr) = NRpars(dcnt).data(pcnt,want1) - NRpars(dcnt).data(pcnt,want2); 

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
            incr = (pmax-pmin)/100;
            list_want = 0:incr:(pmax-pmin);

            correct_rank = zeros(1,length(list_want));
            correct_tie = zeros(1,length(list_want));
            false_ranking = zeros(1,length(list_want));
            false_differentiate = zeros(1,length(list_want));
            false_tie = zeros(1,length(list_want));

            % create data for roughly 60% of the range of parameter values
            % from there, the plot flattens and contains no more info
            for loop = 1:length(list_want)
                delta = list_want(loop);
                for curr = 1:length(subj)
                    if (subj(curr) == 1 && obj(curr) >= delta) || ...
                            (subj(curr) == -1 && obj(curr) <= -delta)
                        correct_rank(loop) = correct_rank(loop) + 1;
                    elseif subj(curr) == 0 && obj(curr) > -delta && obj(curr) < delta
                        correct_tie(loop) = correct_tie(loop) + 1;
                    elseif (subj(curr) == 1 && obj(curr) <= -delta) || ...
                            (subj(curr) == -1 && obj(curr) >= delta)
                        false_ranking(loop) = false_ranking(loop) + 1;
                    elseif (subj(curr) ~= 0 && obj(curr) > -delta && obj(curr) < delta)
                        false_tie(loop) = false_tie(loop) + 1;
                    else
                        false_differentiate(loop) = false_differentiate(loop) + 1;
                    end
                end
            end
            correct_rank = correct_rank / length(subj);
            correct_tie = correct_tie / length(subj);
            false_ranking = false_ranking / length(subj);
            false_differentiate = false_differentiate / length(subj);
            false_tie = false_tie / length(subj);

            % find 1% false ranking level
            choose1 = find( false_ranking<0.01, 1 );
            if isempty(choose1)
                choose1 = length(list_want);
            end
            % find 13% false differentiate leve
            choose2 = find( false_differentiate<0.13, 1 );
            if isempty(choose2)
                choose2 = length(list_want);
            end
            
            choose = max(choose1, choose2);
            
            % print recommended threshold
            fprintf('%17s: %4.2f CI', ...
                threshold_name{tcnt}, list_want(choose));
            fprintf('    (%d %% false ranking, %d %% correct ranking)\n', ...
                round(false_ranking(choose)*100), round(correct_rank(choose)*100));

            % create plot
            figure('name', NRpars(1).par_name{pcnt});
            plot(list_want, correct_rank, 'g', 'linewidth', 2);
            hold on;
            plot(list_want, correct_tie, '-', 'linewidth', 2, 'color', [1 0.9 0]);
            plot(list_want, false_tie, '--', 'linewidth', 2, 'color', [1 0.9 0]);
            plot(list_want, false_differentiate, '--', 'linewidth', 2, 'color', [0.3 0.3 1]);
            plot(list_want, false_ranking, 'r', 'linewidth', 2);

            curr_axis = axis;
            plot([list_want(choose) list_want(choose) list_want(choose) list_want(choose) list_want(choose)], ...
                [correct_rank(choose) correct_tie(choose) false_tie(choose) false_differentiate(choose) false_ranking(choose)], ...
                '*k');
            axis(curr_axis);
            hold off;

            xlabel(['$\Delta$ Metric (' NRpars(1).par_name{pcnt} ')'], 'interpreter','latex')
            ylabel('Frequency', 'interpreter','latex')
            title([sprintf('Compared to %s (', threshold_name{tcnt}) '$\Delta$' sprintf('S = %3.1f)', threshold_level(tcnt)) ], 'interpreter','latex');
            grid on;

            legend('Correct ranking', 'Correct tie', 'False tie', 'False differentiate', ...
                'False ranking', sprintf('%s CI', NRpars(1).par_name{pcnt}), 'location', 'eastoutside');

            0;
        end
    end
    
    
end

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
