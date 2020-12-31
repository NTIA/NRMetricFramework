function [agree_ranking, agree_tie, unconfirmed, disagree] = ...
    analyze_lab2lab( lab1, lab2)
% ANALYZE_LAB2LAB
%   Analyze the conclusions reached by two subjective test labs.
% SYNTAX
%   [agree_ranking, agree_tie, unconfirmed, disagree] = ...
%       analyze_lab2lab( lab1, lab2)
% SEMANTICS
%   Analyze the conclusions reached by two subjective test labs (lab1 and 
%   lab2). Comparisons are made using the Student's t-test. 
%
% Input:
%   lab1 and lab2 contain the same list of media (one per row) and subjects
%   (one per column). An occasional missing score is okay, replaced with NaN.
%   However, an identical set of subjects must rate all stimuli. Deviations
%   from this restriction will yield invalid (random) results.
%
% Output: given stimulus pairs (A, B) 
%   agree_ranking = likelihood that both labs conclude that A has
%       significantly better quality than B (or vice versa).
%   agree_tie = likelihood that both labs conclude A and B have
%       statistically equivalent quality
%   unconfirmed = likelihood that one lab concludes the stimuli are
%       statistically equivalent, but the other lab concludes that
%       A has significantly better quality than B
%   disagree = likelihood that lab1 concludes that A is significantly
%       better than B, but lab2 concludes that A is significantly worse
%       than B (or vice versa)
%
% This function implements the techniques described in this report:
%
% Margaret H. Pinson, "Confidence Intervals for Subjective Tests and
% Objective Metrics That Assess Image, Video, Speech, or Audiovisual
% Quality," NTIA Technical Report TR-21-550, October 2020. 
% https://www.its.bldrdoc.gov/publications/details.aspx?pub=3253

    % record number of stimuli (PVSs)
    num_pvs = size(lab1, 1);
    if size(lab2, 1) ~= num_pvs
        error('Number of stimuli (1st dimension) must be identical');
    end

    % initialize each return variable
    agree_ranking = 0; % both tests conclude that A > B or A < B
    agree_tie = 0; % both tests conclude that A == B 
    unconfirmed = 0; % test 1 can tell a difference, but test 2 cannot (or vice versa)
    disagree = 0; % opposite ranking

    % loop through all stimulus pairs
    for cnt1 = 1:num_pvs
        for cnt2 = cnt1+1:num_pvs
            ans1 = ttest(lab1(cnt1,:), lab1(cnt2,:));
            ans2 = ttest(lab2(cnt1,:), lab2(cnt2,:));
            mosA1 = nanmean(lab1(cnt1,:));
            mosA2 = nanmean(lab1(cnt2,:));
            mosB1 = nanmean(lab2(cnt1,:));
            mosB2 = nanmean(lab2(cnt2,:));
            if ans1 == 1 && ans2 == 1 && mosA1 > mosA2 && mosB1 > mosB2
                agree_ranking = agree_ranking + 1;
            elseif ans1 == 1 && ans2 == 1 && mosA1 < mosA2 && mosB1 < mosB2
                agree_ranking = agree_ranking + 1;
            elseif ans1 == 0 && ans2 == 0 
                agree_tie = agree_tie + 1;
            elseif ans1 == 1 && ans2 == 0 
                unconfirmed = unconfirmed + 1;
            elseif ans1 == 0 && ans2 == 1 
                unconfirmed = unconfirmed + 1;
            else
                disagree = disagree + 1;
            end
        end
    end
    
    % change from count to likelihood
    %
    % we know that total > 0, because all subjective tests have at least
    % two stimuli to be compared, at which point total = 1. 
    total = agree_ranking + agree_tie + unconfirmed + disagree;
    agree_ranking = agree_ranking / total;
    agree_tie = agree_tie / total;
    unconfirmed = unconfirmed / total;
    disagree = disagree / total;

    % print results. Express likelihood as a fraction.
    fprintf('      Stimuli: %d, Subjects: (%d vs %d)\n', ...
        size(lab1,1), size(lab1,2), size(lab2,2));

    fprintf('%4.0f%% Agree Ranking\n', round(100*agree_ranking));
    fprintf('%4.0f%% Agree Tie\n', round(100*agree_tie));
    fprintf('%4.0f%% Unconfirmed\n', round(100*unconfirmed));
    fprintf('%4.2f%% Disagree\n', 100*disagree);

end
