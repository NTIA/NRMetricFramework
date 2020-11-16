function ci_NRpars(nr_dataset, base_dir, feature_function)
% ci_NRpars
%   Estimate the confidence interval (CI) of an NR parameter
% SYNTAX
%   ci_NRpars(nr_dataset, base_dir, feature_function, parnum);
% SEMANTICS
%   Estimate the confidence interval (CI) of an NR metric or parameter, 
%   by comparing the conclusions reached by the model with conclusions 
%   reached by a subjective test. Both will use a constant confidence 
%   interval (CI) to make decisions. The subjective CI is based on
%   5-level ACR MOSs. Two recommended CIs are printed to the command window.
%   (1) ideal CI, and (2) practical CI. The classification types are plotted, 
%   which allows the user to choose an alternate CI.
%
%   By analogy, assess the performance of the metric in terms of an ad-hoc
%   test with N people. This analysis assumes that the metric and MOSs are 
%   compared without statistical tests or confidence intervals. 
%
% Input Parameters:
%   nr_dataset          Data structures, of datasets to be analyzed. If 2+
%                       datasets are provided, then the datasets will be
%                       weighted equally.
%   base_dir            Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature functions (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%
%   The theoretical underpinnings of this algorithm are published in
%   Margaret H. Pinson, "Confidence Intervals for Subjective Tests and
%   Objective Metrics That Assess Image, Video, Speech, or Audiovisual
%   Quality," NTIA Technical Report TR-21-550, October 2020.
%   https://www.its.bldrdoc.gov/publications/details.aspx?pub=3253

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
        
        % reorganize dataset information
        for dcnt = 1:length(nr_dataset)
            dataset_names{dcnt} = nr_dataset(dcnt).test;
            dataset_mos{dcnt} = [nr_dataset(dcnt).media(subset{dcnt}).mos];
            dataset_metrics{dcnt} = [NRpars(dcnt).data(pcnt,subset{dcnt})];
        end
    
        % calculate confidence intervals for this NR metric
        % if the code fails, continue with the next NR metric
        try
            ci_calc(NRpars(1).par_name{pcnt}, ... % current parameter name
                length(nr_dataset), ... % number of datasets
                dataset_names, ... % name of each dataset
                dataset_mos, ...
                dataset_metrics);
        catch
            fprintf('Unexpected error in CI calculations; skipping to next metric.\n\n');
        end
    end 
end

    
