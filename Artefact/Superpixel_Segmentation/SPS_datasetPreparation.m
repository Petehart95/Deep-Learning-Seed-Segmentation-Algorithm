% MComp Research Project | Superpixel Segmentation Script

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the current directory
currentdir = pwd;
outDir1 = strcat(currentdir,'\superDataset\training\seed');
outDir2 = strcat(currentdir,'\superDataset\training\background');
maskDir = strcat(currentdir,'\maskDataset');

% Dialog box for file selection (filter = .jpg,.png)
%[fileNames, pathName, filterIndex] = uigetfile({'*.jpg;*.png;','All Image Files';'*.*','All Files'},'Select Input Images...','MultiSelect', 'on', 'C:\Users\Peter Hart\Documents\GitHub\MCompResearchProject\Artefact\Dataset Preparation\Images');
maskDirInfo = dir(maskDir);
dirlist = dir('.');

fileNames = maskDirInfo.name;
%selectedFile = strcat(pathName,char(fileNames(fileid))); %concatenate selected file and the folder path

%establish a way toload all mask images
%establish a way to load all original images
%establish a way to save super pixel positions (square) in sync with
%original super pixel number.

% Check if only one file is selected
if ~iscell(fileNames)
    fileNames = {fileNames}; % If only one file is selected, ensure the file name is cell and not character
end 
totalFiles = size(fileNames,2); % Store total count for how many files are going to be processed.

%Check if the output directories exist, if not then make them.
if ~exist(outDir1,'dir')
    mkdir(outDir1);
end

if ~exist(outDir2,'dir')
    mkdir(outDir2);
end

h1 = waitbar(0,'Superpixels Processed: 0% along...');
h2 = waitbar(0,'Files Processed: 0% along...');
superID_master = 0;

for fileid=1:totalFiles % Iterate until processed all selected files
    selectedFile = strcat(pathName,char(fileNames(fileid))); %concatenate selected file and the folder path
    im = imread(selectedFile); % Gather input
    dim = size(im(:,:,:));  
    numRows = size(im,1);
    numCols = size(im,2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% SUPER PIXEL SEGMENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    maxSuperPixels = 2000; %Max number of super pixels to be devised.
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
            fileExtension = '.jpeg';
            rprops = regionprops(superMask,'BoundingBox'); %Establish a bounding box
            bbox = rprops.BoundingBox; %surround superpixel with bounding box
            imCropped = imcrop(im, bbox); %crop the original image based on this mask  
            maskOverlay = imcrop(Iout, bbox);      
            if max(maskOverlay) > 0
                fullDestinationFileName = fullfile(outDir1, newFileName);
                imwrite(imCropped,char(fullDestinationFileName));
            else
                fullDestinationFileName = fullfile(outDir2, newFileName);
                imwrite(imCropped,char(fullDestinationFileName));
            end
        end
        perc1 = (superID/maxSuperPixels)*100;
        waitbar(perc1/100,h1,sprintf('Superpixels Processed: %1.1f%% along...',perc1));
    end
    perc2 = (fileid/totalFiles)*100;
    waitbar(perc2/100,h2,sprintf('Files Processed: %1.1f%% along...',perc2));
end

close(h1);
close(h2); %terminate progress bars

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