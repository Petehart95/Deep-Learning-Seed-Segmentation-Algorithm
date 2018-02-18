% MComp Research Project | Superpixel Segmentation Script

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dialog box for file selection (filter = .jpg,.png)
[fileNames, pathName, filterIndex] = uigetfile({'*.jpg;*.png;','All Image Files';'*.*','All Files'},'Select Input Images...','MultiSelect', 'on');

% Check if only one file is selected
if ~iscell(fileNames)
    fileNames = {fileNames}; % If only one file is selected, ensure the file name is cell and not character
end 
totalFiles = size(fileNames,2); % Store total count for how many files are going to be processed.

for fileid=1:totalFiles % Iterate until processed all selected files
    selectedFile = strcat(pathName,char(fileNames(fileid))); %concatenate selected file and the folder path
    A = imread(selectedFile); % Gather input

    [L,N] = superpixels(A,1000);

    figure
    BW = boundarymask(L);
    imshow(imoverlay(A,BW,'cyan'),'InitialMagnification',67)

    outputImage = zeros(size(A),'like',A);
    idx = label2idx(L);
    numRows = size(A,1);
    numCols = size(A,2);
    for labelVal = 1:N
        redIdx = idx{labelVal};
        greenIdx = idx{labelVal}+numRows*numCols;
        blueIdx = idx{labelVal}+2*numRows*numCols;
        outputImage(redIdx) = mean(A(redIdx));
        outputImage(greenIdx) = mean(A(greenIdx));
        outputImage(blueIdx) = mean(A(blueIdx));
    end    

    figure
    imshow(outputImage,'InitialMagnification',67)
end