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
% Input Parameters:
%   nr_dataset          Data structures, of datasets to be analyzed. If 2+
%                       datasets are provided, then the datasets will be
%                       weighted equally.
%   base_dir            Path to directory where NR features and NR parameters are stored.
%   feature_function    Pointer to a no-reference feature functions (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%
%   Details of this algorithm will be published in an NTIA Report. 


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
    
        metric_ci(NRpars(1).par_name{pcnt}, ... % current parameter name
            length(nr_dataset), ... % number of datasets
            dataset_names, ... % name of each dataset
            dataset_mos, ...
            dataset_metrics);
    end 
end

    
