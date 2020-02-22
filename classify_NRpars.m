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
%   3. The number of subjects is ignored (i.e., variance of scores is not
%      normalized by the number of subjects).
%   Data points are only compared within a single dataset, but results from
%   multiple datasets are aggregated into the overall conclusion. Number of
%   subjects is not viewed as an accurate correction factor, because the
%   datasets include lab studies, field studies, and crowdsource studies.
%

    thresh = 0.5;


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
        
        % calculate range of this parameter
        this_par = [];
        for dcnt = 1:length(nr_dataset)
            this_par = [this_par [NRpars(dcnt).data(pcnt,subset{dcnt})]];
        end
        
        fprintf('--------------------------------------------------------------\n');
        fprintf('%d) %s\n\n', pcnt, NRpars(1).par_name{pcnt});
        
        this_par = sort(this_par);
        pmin = this_par(1);
        pmax = this_par(length(this_par));
        fprintf('Full range [%4.2f..%4.2f]\n', pmin, pmax);
        fprintf('95%% of data in range [%4.2f..%4.2f]\n\n', this_par(round(0.025*length(this_par))), this_par(round(0.975*length(this_par))));

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

        % Have all of the data. Now make the plot.
        incr = (pmax-pmin)/100;
        list_want = 0:incr:(pmax-pmin);
        
        correct_decision = zeros(1,length(list_want));
        false_ranking = zeros(1,length(list_want));
        false_differentiate = zeros(1,length(list_want));
        false_tie = zeros(1,length(list_want));
        
        for loop = 1:length(list_want)
            delta = list_want(loop);
            for curr = 1:length(subj)
                if (subj(curr) == 1 && obj(curr) >= delta) || ...
                        (subj(curr) == -1 && obj(curr) <= -delta) || ...
                        (subj(curr) == 0 && obj(curr) > -delta && obj(curr) < delta)
                    correct_decision(loop) = correct_decision(loop) + 1;
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
        correct_decision = correct_decision / length(subj);
        false_ranking = false_ranking / length(subj);
        false_differentiate = false_differentiate / length(subj);
        false_tie = false_tie / length(subj);

        % create plot
        figure('name', NRpars(1).par_name{pcnt});
        plot(list_want, correct_decision, 'g', 'linewidth', 2);
        hold on;
        plot(list_want, false_ranking, 'r', 'linewidth', 2);
        plot(list_want, false_differentiate, '--m', 'linewidth', 2);
        plot(list_want, false_tie, '--y', 'linewidth', 2);
        hold off;
        
        legend('correct decision', 'false ranking', 'false differentiate', 'false tie');
        
        fprintf('\nFalse ranking reaches 1%% when metric threshold is %4.2f\n', list_want( find( false_ranking<0.01, 1 ) ));
        fprintf('\nFalse ranking reaches 0%% when metric threshold is %4.2f\n', list_want( find( false_ranking==0, 1 ) ));
        
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
