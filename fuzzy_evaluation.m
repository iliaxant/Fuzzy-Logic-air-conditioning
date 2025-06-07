%% Testing of Fuzzy System
% After printing useful info about the Fuzzy SystemGenerate random normalized (between -1 and 1) inputs and calculate the 
% output using the airCondition.fis Fuzzy system. Plot the results in a 3D 
% space and create a heatmap showing input MF combinations, dominant output
% MF and their count.

close all;
clear;
clc;


% ---------------- User Input -----------------
rng();  % Leave blank for random inputs or set seed to reproduce results.

numSamples = 1000; % Number of sets of random inputs.
% ---------------------------------------------


fismat = readfis('airCondition');


fprintf('\n------------ Fuzzy System: %s -------------\n', fismat.Name);

for i = 1:numel(fismat.Inputs)
    inputVar = fismat.Inputs(i);
    fprintf('\nInput %d: %-21s (Range: [%.2f %.2f])\n', i, inputVar.Name, ...
        inputVar.Range(1), inputVar.Range(2));
    
    for j = 1:numel(inputVar.MembershipFunctions)
        mf = inputVar.MembershipFunctions(j);
        fprintf('  MF %d: %-15s   Type: %-8s   Params: %s\n', j, mf.Name, ...
            mf.Type, mat2str(mf.Params, 4));
    end
end

outputVar = fismat.Outputs;
fprintf('\nOutput: %-21s (Range: [%.2f %.2f])\n', outputVar.Name,...
    outputVar.Range(1), outputVar.Range(2));

for j = 1:numel(outputVar.MembershipFunctions)
    mf = outputVar.MembershipFunctions(j);
    fprintf('  MF %d: %-15s   Type: %-8s   Params: %s\n', j, mf.Name, ...
        mf.Type, mat2str(mf.Params, 4));
end


fprintf('\n-----------------------------------------------------\n');

fprintf('\nPress a button to initiate testing...\n');
pause;


inputNames = {fismat.Inputs.Name};
outputNames = {fismat.Outputs.Name};

inputData = 2 * rand(numSamples, numel(fismat.Inputs)) - 1;
outputData = evalfis(fismat, inputData);

outputMFIndices = zeros(numSamples, 1);
input1MFIndices = zeros(numSamples, 1);
input2MFIndices = zeros(numSamples, 1);


fprintf('\n\n------- Testing of Air-Condition Fuzzy System -------\n');

for i = 1:numSamples
    fprintf('\nSample #%d\n', i);
    inputVals = inputData(i, :);
    
    for j = 1:numel(fismat.Inputs)
        var = fismat.Inputs(j);
        value = inputVals(j);
        mfIndex = findMaxMF(value, var.MembershipFunctions);
        
        if j == 1
            input1MFIndices(i) = mfIndex;
        else
            input2MFIndices(i) = mfIndex;
        end
        fprintf('Input %s = %.3f => MF: %s\n', var.Name, value, ...
            var.MembershipFunctions(mfIndex).Name);
    end
    
    outVal = outputData(i);
    var = fismat.Outputs;
    mfIndex = findMaxMF(outVal, var.MembershipFunctions);
    outputMFIndices(i) = mfIndex;
    fprintf('Output = %.3f => MF: %s\n', outVal, ...
        var.MembershipFunctions(mfIndex).Name);
end

fprintf('\n-----------------------------------------------------\n\n');

outputMFs = fismat.Outputs.MembershipFunctions;
numOutputMFs = numel(outputMFs);
colors = lines(numOutputMFs);


% -------------- 3D Scatter Plot --------------

figure(1);
set(gcf, 'Position', [250, 150, 1100, 500]);

hold on;

for k = 1:numOutputMFs
    idx = (outputMFIndices == k);
    scatter3(inputData(idx,1), inputData(idx,2), outputData(idx), 80, ...
        'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors(k,:), ...
        'DisplayName', outputMFs(k).Name);
end
xlabel(inputNames{1});
ylabel(inputNames{2});
zlabel(outputNames{1});
title('3D Scatter: Inputs - Output with Output Classification');
grid on;
legend('Location', 'bestoutside');
view(45,30);

hold off;

% ---------------------------------------------


% ------------------ Heatmap ------------------

input1MFs = fismat.Inputs(1).MembershipFunctions;
input2MFs = fismat.Inputs(2).MembershipFunctions;
numInput1MFs = numel(input1MFs);
numInput2MFs = numel(input2MFs);

countMatrix = zeros(numInput1MFs, numInput2MFs);

for i = 1:numInput1MFs
    for j = 1:numInput2MFs
        idx = (input1MFIndices == i) & (input2MFIndices == j);
        countMatrix(i,j) = sum(idx);
    end
end

input1Centers = zeros(numInput1MFs,1);
for i = 1:numInput1MFs
    mf = input1MFs(i);
    if ismember(mf.Type, {'trapmf','trimf'})
        input1Centers(i) = mean(mf.Params);
    elseif strcmp(mf.Type,'gaussmf')
        input1Centers(i) = mf.Params(2);
    else
        input1Centers(i) = mean(mf.Params);
    end
end

input2Centers = zeros(numInput2MFs,1);
for j = 1:numInput2MFs
    mf = input2MFs(j);
    if ismember(mf.Type, {'trapmf','trimf'})
        input2Centers(j) = mean(mf.Params);
    elseif strcmp(mf.Type,'gaussmf')
        input2Centers(j) = mf.Params(2);
    else
        input2Centers(j) = mean(mf.Params);
    end
end

outputMFMap = zeros(numInput1MFs, numInput2MFs);

for i = 1:numInput1MFs
    for j = 1:numInput2MFs
        inputVec = [input1Centers(i), input2Centers(j)];
        outVal = evalfis(fismat, inputVec);
        outputMFMap(i,j) = findMaxMF(outVal, fismat.Outputs.MembershipFunctions);
    end
end

figure(2);
set(gcf, 'Position', [488, 200, 560, 420]);

imagesc(outputMFMap);
colormap(colors);
colorbar('Ticks', 1:numOutputMFs, 'TickLabels', {outputMFs.Name});
title('Input MF Pair => Most Dominant Output MF');
xlabel(fismat.Inputs(2).Name);
ylabel(fismat.Inputs(1).Name);
xticks(1:numInput2MFs);
xticklabels({input2MFs.Name});
yticks(1:numInput1MFs);
yticklabels({input1MFs.Name});
axis square;

for i = 1:numInput1MFs
    for j = 1:numInput2MFs
        text(j, i, num2str(countMatrix(i,j)), ...
            'Color', 'w', 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');
    end
end

% ---------------------------------------------
