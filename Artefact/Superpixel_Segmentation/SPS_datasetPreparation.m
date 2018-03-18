% MComp Research Project | Superpixel Segmentation Script

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Todo:
%establish a way toload all mask images
%establish a way to load all original images
%establish a way to save super pixel positions (square) in sync with
%original super pixel number.

% Get the current directory
currentDir = pwd;
outDir1 = strcat(currentDir,'\superDataset\training\seed');
outDir2 = strcat(currentDir,'\superDataset\training\background');
outDir3 = strcat(currentDir,'\superDataset\mask');
maskDir = strcat(currentDir,'\maskDataset');

[maskFilePaths,maskFileNames] = getAllFiles(maskDir); 

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

check = checkSelectedFiles(maskFileNames,fileNames);
if check == 0
    disp('The input seed images you provided do not match up with the currently generated masks. Cannot generate the training dataset.');
    return;
end

%Check if the output directories exist, if not then make them.
if ~exist(outDir1,'dir')
    mkdir(outDir1);
end

if ~exist(outDir2,'dir')
    mkdir(outDir2);
end

if ~exist(outDir3,'dir')
    mkdir(outDir3);
end

superID_master = 0;
row1 = [];row2 = [];col1 = []; col2 = [];
newSuperPixel = {superID_master,row1,row2,col1,col2};
Tnew = table(newSuperPixel);

totalFiles = length(fileNames); % Store total count for how many files are going to be processed.
totalMasks = length(maskFileNames);
h1 = waitbar(0,'Superpixels Processed: 0% along...'); %Initialise progress bars
h2 = waitbar(0,'Files Processed: 0% along...');

for fileid=1:totalFiles % Iterate until processed all selected files
    width = 1024; % Set a new width size for the image. (Height will be scaled).

    selectedFile = strcat(pathName,char(fileNames(fileid))); %concatenate selected file and the folder path
    im = imread(selectedFile); % Gather input
    dim = size(im(:,:,:));  
    im = imresize(im,[width*dim(1)/dim(2) width],'bicubic');    
    dim = size(im(:,:,:));  
    numRows = size(im,1);
    numCols = size(im,2);
    
    selectedFileName = erase(fileNames(fileid),'.jpg');
    selectedFileName = selectedFileName{:};
    maskFile = strcat(selectedFileName,'.png');
    selectedMask = strcat(maskDir,'\',maskFile);
    imMask = boolean(imread(selectedMask));

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% SUPER PIXEL SEGMENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    maxSuperPixels = 3000; %Max number of super pixels to be devised.
    superPixelGrid = superpixels(im,maxSuperPixels); %Full image superpixel segmentation
    imSuperMask = boundarymask(superPixelGrid); %Full image superpixel segmentation mask

    for superID=1:maxSuperPixels %Iterate through the entire grid of superpixels
        superID_master = superID_master + 1;
        superMask = false(numRows,numCols); %Reset mask
        for i=1:numRows % For each pixel in the image
            for j=1:numCols
                if (superPixelGrid(i,j) == superID) %If this pixel is part of the current super pixel
                    superMask(i,j) = true; %Then include it in the mask
                else
                    superMask(i,j) = false; %Otherwise exclude it
                end
            end
        end
        
        if sum(sum(superMask)) > 0
            newFileName = strcat('superpixel_',num2str(superID_master),'.jpeg');
            fileExtension = '.png';
            rprops = regionprops(superMask,'BoundingBox'); %Establish a bounding box
            bbox = rprops.BoundingBox; %surround superpixel with bounding box
            imCropped = imcrop(im, bbox); %crop the original image based on this mask  
            maskOverlay = imcrop(imMask, bbox);     
            
            %Gather the corner coordinates of the bounding box. To be used
            %for reconstructing the seed mask in a later phase of the CNN.
            row1 = ceil(bbox(2)); row2 = row1 + bbox(3);
            col1 = ceil(bbox(1)); col2 = col1 + bbox(4);
            newSuperPixel = {superID_master,row1,row2,col1,col2};
            Ttemp = table(newSuperPixel);
            Tnew = [Ttemp;Tnew];
            if max(maskOverlay) > 0
                fullDestinationFileName1 = fullfile(outDir1, newFileName);
                fullDestinationFileName2 = fullfile(outDir3, newFileName);
                imwrite(imCropped,char(fullDestinationFileName1));
                imwrite(maskOverlay,char(fullDestinationFileName2));
            else
                fullDestinationFileName1 = fullfile(outDir2, newFileName);
                fullDestinationFileName2 = fullfile(outDir3, newFileName);
                imwrite(imCropped,char(fullDestinationFileName1));
                imwrite(maskOverlay,char(fullDestinationFileName2));
            end
        end
        perc1 = (superID/maxSuperPixels)*100;
        waitbar(perc1/100,h1,sprintf('Superpixels Processed: %1.1f%% along...',perc1));
    end
    perc2 = (fileid/totalFiles)*100;
    waitbar(perc2/100,h2,sprintf('Files Processed: %1.1f%% along...',perc2));
end
%save bounding box positions in table
%write table to a text file
writetable(Tnew,'SPS_coordinates.txt','Delimiter',',')  

close(h1);
close(h2); %terminate progress bars

function [directoryList, fileList] = getAllFiles(dirName)
    dirData = dir(dirName);      %# Get the data for the current directory
    dirIndex = [dirData.isdir];  %# Find the index for directories
    directoryList = {dirData(~dirIndex).name};  %'# Get a list of the files
    fileList = cell(1,length(directoryList));
    for maskCheckID=1:length(fileList)
        fileList{1,maskCheckID} = erase(directoryList{1,maskCheckID},dirName);
    end  
end

function outputFlag = checkSelectedFiles(maskList,selectedFileList)
    selectedFiles = erase(selectedFileList,'.jpg');
    maskFiles = erase(maskList,'.png');
    for n=1:length(selectedFiles)
       outputFlag = false;
       for m=1:length(maskFiles)
           if selectedFiles{1,n}==maskFiles{1,m} 
               outputFlag = true;
               break;
           end
       end
       if outputFlag == false
           break;
       end 
    end
end

function im_BI = rgb2bi(im_greyscale,threshold)
    dim = size(im_greyscale(:,:));  
    im_BI = zeros(dim(1),dim(2));
    
    for i=1:dim(1)
        for j=1:dim(2)
            if im_greyscale(i,j) >= threshold
                im_BI(i,j) = true;
            else
                im_BI(i,j) = false;
            end
        end
    end
end