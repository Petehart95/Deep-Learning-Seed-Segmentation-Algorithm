% MComp Research Project | Superpixel Segmentation Script

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the current directory
currentdir = pwd;
dir1 = strcat(currentdir,'\dataset\training\seed');
dir2 = strcat(currentdir,'\dataset\training\background');

% Dialog box for file selection (filter = .jpg,.png)
[fileNames, pathName, filterIndex] = uigetfile({'*.jpg;*.png;','All Image Files';'*.*','All Files'},'Select Input Images...','MultiSelect', 'on', 'C:\Users\Peter Hart\Documents\GitHub\MCompResearchProject\Artefact\Dataset Preparation\Images');

% Check if only one file is selected
if ~iscell(fileNames)
    fileNames = {fileNames}; % If only one file is selected, ensure the file name is cell and not character
end 
totalFiles = size(fileNames,2); % Store total count for how many files are going to be processed.

%Check if the output directories exist, if not then make them.
if ~exist(dir1,'dir')
    mkdir(dir1);
end

if ~exist(dir2,'dir')
    mkdir(dir2);
end

h1 = waitbar(0,'Superpixels Processed: 0% along...');
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% ESTABLISH SEED MASK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    max_luminosity = 100; 
    threshold = 254;

    srgb2lab = makecform('srgb2lab');
    lab2srgb = makecform('lab2srgb');
    im_lab = applycform(im, srgb2lab);

    L = im_lab(:,:,1)/max_luminosity;

    im_adapthisteq = im_lab;
    im_adapthisteq(:,:,1) = adapthisteq(L)*max_luminosity;
    im_adapthisteq = applycform(im_adapthisteq,lab2srgb);

    im_greyscale = im_adapthisteq(:,:,1);
    im_bi = rgb2bi(im_greyscale,threshold);    
    im_bi = imfill(im_bi,'holes'); 
    
    im_cc = bwconncomp(im_bi);
    im_labelled = labelmatrix(im_cc);

    objectBB = [];
    objectAreas = [];
    for x=1:im_cc.NumObjects 
        objectMatrix = [];
        for i=1:size(im_labelled,1)
            for j=1:size(im_labelled,2)
                if (im_labelled(i,j) == x) 
                    objectMatrix(i,j) = im_bi(i,j);
                end
            end
        end        
        rprops = regionprops(objectMatrix,'BoundingBox');
        objectBB = [objectBB rprops];
        objectAreas = [objectAreas bwarea(objectMatrix)];
    end
    averageArea = round(sum(objectAreas) / length(objectAreas));
    maxArea = round(max(objectAreas));
    Iout = bwareaopen(im_bi, averageArea);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% SUPER PIXEL SEGMENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    maxSuperPixels = 2000; %Max number of super pixels to be devised.
    superPixelGrid = superpixels(im,maxSuperPixels); %Full image superpixel segmentation
    imSuperMask = boundarymask(superPixelGrid); %Full image superpixel segmentation mask

    for superID=1:maxSuperPixels %Iterate through the entire grid of superpixels
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
            newFileName = strcat('seedimage_',num2str(fileid),'_superpixel_',num2str(superID),'.jpeg');
            rprops = regionprops(superMask,'BoundingBox'); %Establish a bounding box
            bbox = rprops.BoundingBox; %surround superpixel with bounding box
            imCropped = imcrop(im, bbox); %crop the original image based on this mask  
            maskOverlay = imcrop(Iout, bbox);      
            if max(maskOverlay) > 0
                fullDestinationFileName = fullfile(dir1, newFileName);
                imwrite(imCropped,char(fullDestinationFileName));
            else
                fullDestinationFileName = fullfile(dir2, newFileName);
                imwrite(imCropped,char(fullDestinationFileName));
            end
        end
        perc1 = (superID/maxSuperPixels)*100;
        waitbar(perc1/100,h1,sprintf('Superpixels Processed: %1.1f%% along...',perc1));
    end
    perc2 = (fileid/totalFiles)*100;
    waitbar(perc2/100,h2,sprintf('Files Processed: %1.1f%% along...',perc2));
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