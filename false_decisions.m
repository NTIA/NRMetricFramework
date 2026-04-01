function [rate, threshold_level] = false_decisions(mos, metric)
% false_decisions
%   Estimate the false decision rate of a video quality metric.
% SYNTAX
%   [rate threshold_level] = false_decisions(mos, metric)
%   [rate threshold_level] = false_decisions(ratings, metric)
% SEMANTICS
%   This function calculates the false decision rate of a metric, when
%   compared to a subjective test. Note that metric decisions are
%   deterministic (better, worse, or identical) while the subjective
%   test's decisions use confidence intervals to reach statistically
%   significant conclusions. The false decision rate is computed  
%   as follows:
%
%   The numerator is the incidence rate where the metric will say
%   (A) is better than (B) when a subjective test would say that the
%   quality of (A) is significantly worse than the quality of (B). 
%
%   The denominator is the incidence rate where the metric says that (A)
%   and (B) have different quality. Metric ties are ignored. 
%
%   Incidents where the metric concludes that (A) and (B) have the same quality
%   are ignored.
%
%   If the 1st input parameter is a vector of mean opinion scores
%   (MOS), a default MOS confidence interval of 0.5 will be used. If the 1st 
%   input parameter is a matrix of subject ratings (video, subject), then the
%   confidence interval of the dataset will be computed and used.
%
% Input Parameters:
%   mos     For one dataset, a double array that contains the mean opinion
%           score (mos) for each stimulus in the dataset ... OR ...
%   ratings For one dataset, a matrix (simuli, subjects) that contains
%           individual subject ratings for each stimuli in the dataset.
%   metric  For one dataset, a double array that contains one metric's
%           value for each stimuli in the dataset. Order of stimuli must be
%           identical to input variable mos.
%
% Output Parameters:
%   rate       False decision rate (expressed as a fraction)
%   threshold_level  Confidence interval threshold (calculated or default)
%
%   The theoretical underpinnings of this algorithm are published in
%   Margaret H. Pinson, "Confidence Intervals for Subjective Tests and
%   Objective Metrics That Assess Image, Video, Speech, or Audiovisual
%   Quality," NTIA Technical Report TR-21-550, October 2020.
%   https://www.its.bldrdoc.gov/publications/details.aspx?pub=3253


    % Analysis of subjective tests yields several constants that are used by
    % this function. This constant is computed from lab-to-lab comparisons
    % of subjective tests (see above).  
    if isvector(mos)
        % Use the default CI for a 5-point ACR test, where 95% of stimuli mos can be rank ordered
        threshold_level = 0.5; 
        
    elseif ismatrix(mos)
        % Calculate the actual CI for this dataset
        [threshold_level, mos] = compute_data_CI(mos);
        fprintf('\nUsing the dataset''s actual confidence interval of %4.2f to compute false decision rate.\n\n', threshold_level);
    end

    % Metric has no range of values. False ranking rate is undefined.
    if min(metric) == max(metric)
        rate = nan;
        return;
    end

    % manually loop through all pairs of stimuli
    curr = 1;
    curr_len = length(mos);
    subj = nan(1, (curr_len-1)*curr_len/2);
    obj = nan(1, (curr_len-1)*curr_len/2);
    for mcnt1 = 1:curr_len
        for mcnt2 = mcnt1+1:curr_len

            % subj(curr) is decision whether #1 is better,
            % equivalent, or worse than #2
            diff = mos(mcnt1) - mos(mcnt2);
            if diff > threshold_level
                subj(curr) = 1;
            elseif diff < -threshold_level
                subj(curr) = -1;
            else
                subj(curr) = 0;
            end

            % repeat for objective metric, but no threshold
            diff = metric(mcnt1) - metric(mcnt2);
            if diff > 0
                obj(curr) = 1;
            elseif diff < 0
                obj(curr) = -1;
            else
                obj(curr) = 0;
            end

            % increment storage counter
            curr = curr + 1;
        end
    end


    % compute false ranking rate
    rate = 0;   
    not_rate = 0;
    for curr = 1:length(subj)
        if subj(curr) ~= 0 && subj(curr) == -obj(curr)
            rate = rate + 1;
        elseif obj(curr) ~= 0
            not_rate = not_rate + 1;
        end
    end
    rate = rate / (rate + not_rate);
    
end


%-------------------------------------------------------------------------
% Calculate the confidence interval (CI) for this dataset, given the matrix
% of subject ratings. 
function [threshold_level, mos] = compute_data_CI(ratings)

    % Take raw subjective ratings: one media per row, subjects in columns
    % For each pair of media, compute better-equal-worse (BEW) of:
    %   bew = 0 for equivalent, bew = 1 for better or worse
    % Also compute the delta between subjective ratings for this pair
    %    deltaS = distance between the two video MOSs
    [num, max_subjects] = size(ratings);
    
    if ~isnumeric(max_subjects)
        error('Number of subjects must be a number, >= 1');
    end
    
    bew = nan(1,(num*(num-1))/2);
    deltaS = nan(1,(num*(num-1))/2);
    curr = 1;
    for cnt1=1:num
        for cnt2 = cnt1+1:num
            bew(curr) = ttest(ratings(cnt1,1:max_subjects), ratings(cnt2,1:max_subjects));
            deltaS(curr) = abs( nanmean(ratings(cnt1,1:max_subjects)) - nanmean(ratings(cnt2,1:max_subjects)) );
            curr = curr + 1;
        end
    end


    % Compute fraction of MOS comparisons that are significantly different for
    % different MOS deltas, based on Student's t-test better/equivalent/worse
    % do this at 0.1 MOS intervals from zero (identical) to 2 (halfway
    % through the 5-point MOS scale). 
    
    delta = 0.1;
    bins = 0:delta:2;
    
    bin_lower = bins - delta/2;
    bin_upper = bins + delta/2;
    bin_upper(length(bin_upper)) = 4;
    
    better = nan(1,length(bins));
    
    % all data
    for cnt=1:length(bins)
        better(cnt) = nanmean(bew(deltaS >= bin_lower(cnt) & deltaS < bin_upper(cnt)));
    end
    
    % Find the 95% CI level. Err on the larger value
    if better(length(better)) < 1
        error('This dataset cannot differentiate between stimuli at the 95\% confidence level');
    end
    tmp = find(better >= 0.95, 1);
    threshold_level = bins(tmp);

    % Also return MOS
    mos = nanmean(ratings, 2);
end
