% MComp Research Project | Superpixel Segmentation Script

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the current directory
currentDir = pwd;
groundTruthDir = 'C:\Users\Peter Hart\Documents\GitHub\MCompResearchProject\Artefact\Superpixel_Segmentation\output\test output\selected';
predictedDir = 'C:\Users\Peter Hart\Documents\GitHub\MCompResearchProject\Artefact\Superpixel_Segmentation\output\test output\predicted';

% Dialog box for file selection (filter = .jpg,.png)
[fileNames, pathName, filterIndex] = uigetfile({'*.jpg;*.png;','All Image Files';'*.*','All Files'},'Select Input Images for Superpixel segmentation','MultiSelect', 'on');

%Check if any files were actually selected by the user, if not terminate script.
% if fileNames == 0
%     disp("Error: No input RGB images were selected by the user...");
%     return;
% end

% Check if only one file is selected
if ~iscell(fileNames)
    fileNames = {fileNames}; % If only one file is selected, ensure the file name is cell and not character
end 

totalFiles = length(fileNames); % Store total count for how many files are going to be processed.
totalOverlapRatio = 0;

for fileNo=1:totalFiles % Iterate until processed all selected files
    selectedFile = strcat(pathName,char(fileNames(fileNo))); %concatenate selected file and the folder path
    groundTruth = imread(selectedFile); % Gather input
    dim = size(groundTruth(:,:,:));  
    
    selectedFileName = erase(fileNames(fileNo),'.png');
    selectedFileName = selectedFileName{:};
    selectedPredicted = strcat(predictedDir,'\',selectedFileName,'.jpg');
    
    predicted = imread(selectedPredicted);
    predicted = im2bw(predicted,0.5);
    
    gtmeasurements = regionprops(groundTruth, 'BoundingBox');
    gt = gtmeasurements.BoundingBox; %surround superpixel with bounding box
    
    prmeasurements = regionprops(predicted,'BoundingBox');
    pr = prmeasurements.BoundingBox; 

    overlapRatio = bboxOverlapRatio(gt,pr);
    totalOverlapRatio = totalOverlapRatio + overlapRatio;
end

meanOverlap = totalOverlapRatio / totalFiles;