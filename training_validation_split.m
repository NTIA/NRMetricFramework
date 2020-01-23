function [boolean_array, alt_train, alt_validation] = training_validation_split(y, probability)
%Training Validation Split
%   This function returns a p, 1-p split of the data into two separate
%   matrices for independent testing and validation of data. This is supposed
%   to be generically used to split data into testing and validation sets. 
%   p represents the percentage of training data you'd like to use. 
%   Namely, p = .8 means that I'd like 80% of the data to be used for
%   training. This function creates a separate split from the already
%   internal split caused by the processing of data.
%
%   This other internal split is stored in the media structure where files
%   are labeled training and validation appropriately.
%
% SYNTAX
%
% Should be self explanatory but an 80 - 20 split looks like
%   [train, valid] = training_validation_split(dataset, .8);
% ----------------------------------------------------------
    assert(probability < 1 && probability > 0, "Expecting probability < 1 and probability > 0.") 
    
    n_points = length(y);
    take_point = randperm(n_points);
    
    %Look up the matlab matrix indexing guide here. Namely about logical
    %indexing. But the point is you can select the rows you want by passing
    %in a logical array that contains non-zero values for the rows you want
    %and 0 for the rows you don't. This logical array can be created in any
    %fashion you want. 
    boolean_array = take_point <= round(n_points * probability);
    %shuffle boolean array
    boolean_array(randperm(length(boolean_array)));
    alt_train = y(boolean_array);
    alt_validation = y(~boolean_array);
end

