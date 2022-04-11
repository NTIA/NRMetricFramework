function [rate] = false_decisions(mos, metric)
% false_decisions
%   Estimate the false decision rate for an NR parameter
% SYNTAX
%   [rate] = false_decisions(mos, metric)
% SEMANTICS
%   The numerator is the incidence rate where the metric will say
%   (A) is better than (B) when a subjective test would say that the
%   quality of (A) is significantly worse than the quality of (B). 
%
%   The denominator is the incidence rate where the metric says that (A)
%   and (B) have different quality. Metric ties are ignored. 
%
%   Incidents where the metric concludes that (A) and (B) have the same quality
%   are not penalized. 
%
% Input Parameters:
%   mos     For one dataset, a double array that contains the mean opinion
%           score (MOS) for each stimuli in the dataset.
%   metric  For one dataset, a double array that contains one metric's
%           value for each stimuli in the dataset. Order of stimuli must be
%           identical to input variable MOS.
%
%   The theoretical underpinnings of this algorithm are published in
%   Margaret H. Pinson, "Confidence Intervals for Subjective Tests and
%   Objective Metrics That Assess Image, Video, Speech, or Audiovisual
%   Quality," NTIA Technical Report TR-21-550, October 2020.
%   https://www.its.bldrdoc.gov/publications/details.aspx?pub=3253
%
% Output Parameters
%   rate =  The false ranking rate, expressed as a fraction. 
%           Metric ties are omitted from this calculation.

    % Analysis of subjective tests yields several constants that are used by
    % this function. These constants are computed from lab-to-lab comparisons
    % of subjective tests (publication pending).  
    threshold_level = 0.5; % delta S, where 95% of stimuli MOS can be rank ordered
    
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


    % compute false ranking ra
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

