function [Xtrain, Xtest, ytrain, ytest] = export_NRpars(datasets, param_structs, param_list, format, fname)
% EXPORT_NRPARS
%
%   Write NR parameters or NR metrics and MOSs to a spreadsheet or matrix
%
% SYNTAX
%
% [Xtrain, Xtest, ytrain, ytest] = paramToMatrix(dataset, param_structs,
%           param_list, format, fname);
% 
% SEMANTICS
%
%  The dataset structures and NR parameter structures are complex.
%   
%  This function exports just the data needed to train or test a parameter
%  or metric. Data are formatted into matrixes and exported.
%  Four matricies are returned (Xtrain, Xtest, ytrain, and ytest) to
%  facilitate proper seperation of training and verification data.
%
% Arguments
%
%   dataset: The dataset from which all param_structs are computed from.
%
%   param_structs: one or more parameter structures (a vector).
%
%   param_list: The array of strings which correspond to the desired
%   parameters within the param_structs array. Input as an empty array ([])
%   if all parameters in all structs are desired.
%
%   format: The format the user would like to export the matrices as.
%   Options are "csv" and "excel" for csv and excel files respectively. The
%   user can also input "none" if no exporting is neccesary
%
%   fname: The filename the user would like to export the matrices as. If
%   the option "none" is inputted, this parameter does not matter. If "csv"
%   is chosen, then the prefixes "test_" and "train_" will be prepended. 
%
%Output
%
%  Xtrain: The feature matrix for training
%  Xtest: The feature matrix for testing
%  ytrain: The MOS vector for training
%  ytest: The MOS vector for testing
%   
% Examples:
%
% % return all parameters from NR_pars1 as MATLAB variables
% [Xtrain, Xtest, ytrain, ytest] = paramToMatrix(Example_Dataset, NR_pars1, ...
%       [], "none", "none")
%
% % save five parametes from three different parameter structs to a CSV file
% % and return the same data to MATLAB variables.
% [Xtrain, Xtest, ytrain, ytest] = paramToMatrix(Example_Dataset, ...
%       [NR_pars1, NR_pars2, NR_pars3], [Parm1, Param2, Param3, Param4, Param5], "csv", "test.csv")
%
% % save one parameter to an Excel spreadsheet
% paramToMatrix(Example_Dataset, NR_pars1, Parm1, "excel", "test.xls")
%
%--------------------------------------------------------------------------

    %Aggregate MOS scores
    MOS_cell_array = [];
    %Get Training Testing Split
    training_bool_array = [];
    media_to_index = containers.Map;
    index = 1;
    for i = 1:length(datasets)
        current_dataset = datasets(i);
        %Note that current_data_set.media is a struct array and returns the mos
        %as a csv, therefore you need to enclose the whole thing in square
        %brackets to cast it to an array
        MOS_cell_array = [MOS_cell_array, [current_dataset.media(:).mos]];    
        training_bool_array = [training_bool_array; get_training_validation(current_dataset)];
        for media_index = 1:length(current_dataset.media)
            current_media = current_dataset.media(media_index);
            media_to_index(current_media.name) = index;
            index = index + 1;
        end
    end
    y = MOS_cell_array';

    %Set flag to decide if we're going to take all the features or a list
    
    take_all = false;
    if(isempty(param_list))
        take_all = true;
    end
    
    %Basic algorithm goes as follows:
    %   Iterate through the param_list, where for each parameter name we
    %   iterate through the param_struct and look through the par_names
    %   field to try to find the parameter name. If it fails, then we error
    %   out, if we succeed we take the row of data from that parameter
    %   struct and transpose it, before concatenating to the X matrix.
    parameter_names = [];
    X = [];
    if(take_all)
        param_list = [param_structs.par_name];
    end
    
    for j = 1:length(param_list)
        X_row = [];
        found = false;
        searching_for = param_list(j);
        for k = 1:length(param_structs)
            current_struct = param_structs(k);
            field_names = [current_struct.par_name];
            media_names = [current_struct.media_name];
            order_vector = zeros(length(media_names), 1);
            %Get Media Names and set permutation order
            for i = 1:length(media_names)
                order_vector(i) = media_to_index(media_names{i});
            end
            %Look through struct names
            [lia, locb] = ismember(searching_for, field_names);
            %Break if parameter name is not found
            if(~lia)
                continue
            else
                parameter_names = [parameter_names, searching_for];
                X_row = current_struct.data(locb, :);
                break;
            end
        end
        %Match Valid Ordering
        [~, index] = sortrows(order_vector);
        X_col = X_row';
        X_col = X_col(index, :);
        %Append Row to the Matrix as a Column
        X = [X, X_col];
    end
    [Xtrain, Xtest, ytrain, ytest] = training_testing_split(X, y, logical(training_bool_array)); 
    %This function additionally exports the matrix to the desired format
    column_names = matlab.lang.makeValidName(["mos", parameter_names]);
    training_data = array2table([ytrain, Xtrain]);
    testing_data = array2table([ytest, Xtest]);
    testing_data.Properties.VariableNames = column_names;
    training_data.Properties.VariableNames = column_names;
    export_format(training_data, testing_data, fname, format); 
end

function bool_array = get_training_validation(dataset)
    bool_array = zeros(length(dataset.media),1);
    for row_index = 1:length(dataset.media)
        row = dataset.media(row_index);
        if(row.category2 == "train")
            bool_array(row_index) = 1;
        end
    end
end


function [Xtrain, Xtest, ytrain, ytest] = training_testing_split(Xin, yin, boolean_array)
    Xtrain = Xin(boolean_array, :);
    Xtest = Xin(~boolean_array, :);
    ytrain = yin(boolean_array, :);
    ytest = yin(~boolean_array, :);
end 

function export_format(training_data, testing_data, fname, format)
    switch format
        case 'csv'
            writetable(training_data, "train_" + fname);
            writetable(testing_data, "test_" + fname);
        case 'excel'
            writetable(training_data, fname, "Sheet", "Training Data");
            writetable(testing_data, fname, "Sheet", "Testing Data");
        case 'none'
    end

end
    
