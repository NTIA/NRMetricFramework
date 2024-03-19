all_data = readtable('vcrdci_123_all_data_eg_no_nans.csv');

% filter for raw mos values over 60
all_data = all_data(all_data.raw_mos >= 60, :); 

% first 500 values
% note: as mentioned in the workflow, taking a random subset would be better. this is just for simplicity!
all_data = head(all_data, 500);

% one hot encode categorical data
all_data.EgCodecCategory = categorical(all_data.EgCodecCategory);

encData = table();

categoricalStart = 4;
categoricalEnd = 4;

for i=categoricalStart:categoricalEnd
 encData = [encData onehotencode(all_data(:,i))];
end

% concatenate normal data and one hot encoded data
all_data = [all_data(:, 1:categoricalStart - 1) encData all_data(:, categoricalStart + 1:end)];

labels = all_data(:, 3);
features = all_data(:, 4:end);

numFeatures = width(features);

data_mean = zeros(1, numFeatures);
data_std = zeros(1, numFeatures);

% calculate info for normalization layer
for j = 1:numFeatures
    data_col = table2array(features(:, j));
    data_mean(j) = mean(data_col);
    data_std(j) = std(data_col);
end

% load and configure all layers
modelFolder = "vcrdci123_small_model";

netLayers = importTensorFlowLayers(modelFolder, "OutputLayerType","regression");

placeholders = findPlaceholderLayers(netLayers);

norm1 = placeholders(1);
norm2 = placeholders(2);

matInputLayer = featureInputLayer(numFeatures, "Normalization","zscore", "Mean", data_mean, "StandardDeviation", data_std);
matNormLayer = layerNormalizationLayer();

netLayers.Layers

% note: the names of these layers might be different. To print out all the layers, run the following command (no semicolon):
% netLayers.Layers
% then, replace the names of the layers in the code with the names of the first three layers
netLayers = replaceLayer(netLayers, "normalization_input", matInputLayer);
netLayers = removeLayers(netLayers, 'normalization');
netLayers = connectLayers(netLayers,'input','dense');

net = assembleNetwork(netLayers);

% test assembled network
featureTestData = readtable("feature_test_vcrdci123_small.csv");
featureTestData = featureTestData(2:end,:);

predictions = predict(net, featureTestData);    
predictions;
tf_predictions = fileread("predictions.txt");
tf_predictions = erase(erase(tf_predictions, "["), "]");
tf_predictions = sscanf(tf_predictions, "%f");

prediction_differences = tf_predictions - predictions;

mean(prediction_differences)
max(prediction_differences)