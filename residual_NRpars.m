function residual_NRpars(nr_dataset, base_dir, varargin)
% residual_NRpars
%   Compare an NR metric with the residuals of a baseline NR metric.
% SYNTAX
%   residual_NRpars(nr_dataset, base_dir, feature_function1, feature_num1, ...
%       feature_function2, feature_num2, ..., feature_functionN, feature_numN);
% SEMANTICS
%   The following analysis is performed for all combinations of a set of
%   features. One NR metric is specified as the auxiliary metric. The other
%   NR metrics are combined into a baseline model. Analyze the added value 
%   of the auxiliary metric, by comparing it to the residuals of the
%   baseline model. 
%
%   This analysis intentionally omits stimuli marked for verification
%   purposes only.
%
% Input Parameters:
%   nr_dataset          Data structure. Each array element describes an 
%                       entire dataset with fields "name", "file_location", etc.
%   base_dir            Path to directory where NR features and NR parameters are stored.
%   feature_functionX   The Xth pointer to a no-reference feature function (NRFF) that must 
%                       adhere to the interface specified in calculate_NRpars.
%   feature_numX        The Xth NR metric's parameter number (feature_functionX).
%
%   1) Train model using all baseline NRFF NRFF listed.
%   2) Calculate residuals between MOS and this baseline model
%   3) Compare auxiliary metric to the residuals between MOS and the
%      baseline model
%   4) Plot results, with supplemental information printed
%
%   These calculations are performed for each dataset separately.
%
% Warning:
%   Currently only works for one dataset. 

    total_NRpars = 0;

    cnt = 1;
    varargin_len = nargin-2;
    while cnt <= varargin_len
        if cnt + 1 <= varargin_len
            total_NRpars = total_NRpars + 1;
            feature_function{total_NRpars} = varargin{cnt};
            NRnum(total_NRpars) = varargin{cnt+1};
            cnt = cnt + 2;            
        else
            error('optional input argument %s not recognized or not formatted correctly', char(varargin{cnt}));
        end
    end

    if total_NRpars < 2
        error('Must specify at least two NR metrics.')
    end

    if length(nr_dataset) > 1 || length(nr_dataset) < 1
        error('Function only currently works for exactly one dataset')
    end

    % load the parameters. This will calculate them, if not yet computed. 
    fprintf('Loading NR parameters. This will be very slow, if not yet calculated\n');
    for cnt=1:total_NRpars
        NRpars(cnt) = calculate_NRpars(nr_dataset, base_dir, 'none', feature_function{cnt});
    end
    fprintf('NR parameters loaded\n\n');

    % discard media with values of inf or nan
    % discard everywhere (i.e., the dataset and all NRpars structures)
    % this is permanent tampering. Make sure none of these variables are
    % retained when this function exits!
    keep = true(1,length([nr_dataset.media]));
    for cnt=1:total_NRpars
        keep = keep & isfinite(NRpars(cnt).data(NRnum(cnt),:));
    end
    for cnt=1:total_NRpars
        tmp = NRpars(cnt).data;
        NRpars(cnt).data = tmp(:, keep);
        NRpars(cnt).computed = NRpars(cnt).computed(keep);
        NRpars(cnt).media_name = NRpars(cnt).media_name(keep);
    end
    nr_dataset.media = nr_dataset.media(keep);

    % pick off training media for this dataset
    subset = [nr_dataset.media(:).category2] == categorical({'train'});

    % repeat residual calculations for each NR metric in turn.
    for cnt=1:total_NRpars
        specific_residual(nr_dataset, subset, NRpars, NRnum, cnt);
    end
    
end


% analyze residuals with one specific NR metric as the auxiliary
function specific_residual(nr_dataset, subset, NRpars, NRnum, aux_num)

    % define the baseline model, as all NR metrics other than aux_num
    baseline = [1:aux_num-1 aux_num+1:length(NRpars)];
    total_NRpars = length(NRpars);

    fprintf('\n*************************************************************\n');

    % %%%% Part 1 %%%%
    % Organize data for baseline linear regression, as per the variable
    % "baseline" defined above. 
    mos = [nr_dataset.media(subset).mos]';
    ydata = mos;

    % xdata(:,1) is all ones, so that linear regresssion produces a
    % constant term. The other columns each have one of the NR metrics in
    % the baseline model, so that we compute a weight for each of them.
    xdata = ones(length(mos),total_NRpars);
    for cnt=1:total_NRpars-1
        curr = baseline(cnt); 
        xdata(:,cnt+1) = NRpars(curr).data(NRnum(curr),subset);
    end
    
    % linear regression. W is the weights.
    lastwarn('');
    warning('off', 'MATLAB:rankDeficientMatrix');
    w = xdata \ ydata;
    warning('on', 'MATLAB:rankDeficientMatrix');
    [~,warnID] = lastwarn;
    if exist(warnID) && warnID == 'MATLAB:rankDeficientMatrix'
        % Suppress warning print for rank deficient models. 
        fprintf('Rank deficient matrix indicates that one or more of the NR metrics is irrelevant for this baseline model');
    end

    % calculate residuals
    resid = ydata - xdata * w;
    yhat = xdata * w;

    % print the baseline metric
    fprintf('Dataset %s\n', nr_dataset.dataset_name);
    fprintf('Baseline metric:\n')
    for cnt=1:total_NRpars-1
        curr = baseline(cnt);
        fprintf('  x%d = %s\n', cnt, NRpars(curr).par_name{NRnum(curr)});
    end
    fprintf('Model for baseline: MOS = %5.2f', w(1));
    for cnt=1:total_NRpars-1
        fprintf(' + %5.2f * x%d', w(cnt+1), cnt);
    end
    fprintf('\n');

    % calculate Pearson correlation between MOS and baseline metric
    base_corr = corrcoef(ydata,  xdata*w);
    fprintf('Correlation to MOS: %5.2f\n', base_corr(1,2));

    % calculate the new fit line of the baseline model. Save this for later plotting.
    % xdata2 is the baseline model (after fitting).
    xdata2 = ones(length(ydata),2);
    xdata2(:,2) = yhat;
    w = xdata2 \ ydata;
    Bxmin = min(yhat);
    Bxmax = max(yhat);
    Bymin = w(1) + Bxmin * w(2);
    Bymax = w(1) + Bxmax * w(2);

    % %%%% Part 1 %%%%
    % Plot the baseline metric on the left side

    % plot baseline metric on left
    figure('Name',sprintf('Dataset %s', nr_dataset.dataset_name), 'NumberTitle', 'off');
    subplot(2,2,1)
    plot( yhat, ydata, '.b')
    
    % plot the baseline fit.
    hold on;
    plot([Bxmin Bxmax],[Bymin Bymax],'-r','LineWidth',1);
    hold off;

    % fill 'baseline_string' with the NR metrics in the baseline model
    baseline_string = '(';
    for cnt=1:total_NRpars-1
        if cnt > 1
            baseline_string = [baseline_string ','];
        end
        curr = baseline(cnt);
        baseline_string = [baseline_string NRpars(curr).par_name{NRnum(curr)}];
    end
    baseline_string = [baseline_string ')'];
    
    % if string is too long, replace it with just the number of NR metrics
    % take a wild guess that 70 characters is too much
    if length(baseline_string) >= 70
        baseline_string = sprintf('(%d NR metrics)', total_NRpars);
    end
    
    % Add labels. Set X and Y axis range. 
    ylabel('MOS')
    xlabel({'Baseline Metric', baseline_string});
    title({'Baseline Metric', sprintf('%5.2f\\rho MOS (%s)', base_corr(1,2), nr_dataset.dataset_name)});

    % make sure x-axis and y-axis are at least [1..5];
    tmp = axis;
    axis([min(tmp(1),1) max(tmp(2),5) min(tmp(3),1) max(tmp(4),5)])

    % plot residuals in the lower right
    subplot(2,2,3)
    plot(yhat, ydata - yhat, '.b')

    % Add labels. Set X and Y axis range. 
    ylabel({'Residuals','(MOS - Baseline)'})
    xlabel({'Baseline Metric', baseline_string});
    hold on;
    plot([1 5],[0 0], '-k')
    hold off;


    % %%%% Part 2 %%%%
    % plot auxiliary parameter vs MOS in the upper right

    % organize data 
    xdata = NRpars(aux_num).data(NRnum(aux_num),subset)';
    ydata = mos;
    
    % check if all values are identical or if no data is left
    % after eliminating inf and nan. If so, skip this case.
    if length(ydata) < 2 || max(xdata) == min(xdata) 
        fprintf('All data identical or missing; cannot calculate fits\n');
        plot_valid = false;
    else 
        plot_valid = true;
    end


    % plot auxiliary metric on upper right
    subplot(2,2,2)
    if plot_valid
        % calculate Pearson correlation between MOS and auxiliary metric
        corr = corrcoef(ydata,  xdata);
        fprintf('\nAuxiliary metric %s\nCorrelation to MOS: %5.2f\n\n', ...
            NRpars(aux_num).par_name{NRnum(aux_num)}, corr(1,2));  

        % plot data
        plot( xdata, ydata, '.b')
        
        % calculate the new fit line
        tmp = xdata;
        xdata = ones(length(xdata),2);
        xdata(:,2) = tmp;
        w = xdata \ ydata;
        xmin = min(xdata(:,2));
        xmax = max(xdata(:,2));
        ymin = w(1) + xmin * w(2);
        ymax = w(1) + xmax * w(2);
    
        % plot the mos fit.
        hold on;
        plot([xmin xmax],[ymin ymax],'-r','LineWidth',1);
        hold off;
    else
        % auxiliary metric has no valid data points
        plot([0 1], [0 1], '-w');
        text(0.25, 0.25, 'Constant or undefined value');
        corr(1,2) = 0;
    end

    % Add labels
    ylabel('MOS')
    xlabel({'Auxiliary Metric', sprintf('(%s)', NRpars(aux_num).par_name{NRnum(aux_num)})})
    title({'Auxiliary Metric', sprintf('%5.2f\\rho MOS (%s)', corr(1,2), nr_dataset.dataset_name)});


    % %%%% Part 3 %%%%

    % organize data for target linear regression (auxiliary NR metric
    % vs residuals of the baseline model)
    xdata = ones(sum(subset),2);
    xdata(:,2) = NRpars(aux_num).data(NRnum(aux_num),subset);
    ydata = resid;
    
    % check if all values are identical or if no data is left
    % after eliminating inf and nan. If so, skip this case.
    if length(resid) < 2 || max(xdata(:,2)) == min(xdata(:,2)) 
        fprintf('All data identical or undefined; cannot calculate\n');
        plot_valid = false;
    else 
        plot_valid = true;
    end

    % plot results on lower right
    subplot(2,2,4)
    
    if plot_valid
        % linear regression. W is the weights.
        w = xdata \ ydata;
        
        % calculate Pearson correlation between MOS and auxiliary metric
        corr = corrcoef(ydata,  xdata*w);
    
        % print the residual model, accuracy
        fprintf('Auxiliary residual model: %5.2f + %5.2f * x1\n', w(1), w(2));
        fprintf('Correlation to residuals: %5.2f\n\n', corr(1,2));      

        % plot data
        plot( xdata * w, ydata, '.b')
        
        % calculate the new fit line
        xdata(:,2) = xdata * w;

        warning('off', 'MATLAB:rankDeficientMatrix');
        w = xdata \ ydata;
        warning('on', 'MATLAB:rankDeficientMatrix');

        xmin = min(xdata(:,2));
        xmax = max(xdata(:,2));
        ymin = w(1) + xmin * w(2);
        ymax = w(1) + xmax * w(2);
    
        % plot horizontal line at zero residuals, and plot the baseline fit.
        hold on;
        plot([xmin xmax],[0 0], '-k')
        plot([xmin xmax],[ymin ymax],'-r','LineWidth',1);
        hold off;
    else
        % auxiliary metric has no valid data points
        plot([0 1], [0 1], '-w');
        text(0.25, 0.25, 'Constant or undefined value');
        corr(1,2) = 0;
    end

    % Add labels
    ylabel({'Residuals','(MOS - Baseline)'})
    xlabel({'Auxiliary Metric', sprintf('(%s)', NRpars(aux_num).par_name{NRnum(aux_num)})})
    title(sprintf('%5.2f\\rho to Residuals (MOS - Baseline)', corr(1,2)));

end

