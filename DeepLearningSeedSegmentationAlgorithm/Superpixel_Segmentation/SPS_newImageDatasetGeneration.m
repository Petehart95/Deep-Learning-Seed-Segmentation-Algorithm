% MComp Research Project | Superpixel Segmentation Script

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the current directory
currentDir = pwd;
outDir = strcat(currentDir,'\outputImage_superDataset');

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

%Check if the output directories exist, if not then make them.
if ~exist(outDir,'dir')
    mkdir(outDir);
end

superID_master = 0;
row1 = 0;row2 = 0;col1 = 0; col2 = 0;
newSuperPixel = {superID_master,row1,row2,col1,col2};
Tnew = table(newSuperPixel);

totalFiles = length(fileNames); % Store total count for how many files are going to be processed.

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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%% SUPER PIXEL SEGMENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    maxSuperPixels = 3000; %Max number of super pixels to be devised.
    superPixelGrid = superpixels(im,maxSuperPixels); %Full image superpixel segmentation
    imSuperMask = boundarymask(superPixelGrid); %Full image superpixel segmentation mask
    
    for superID=1:maxSuperPixels %Iterate through the entire grid of superpixels
        superID_master = superID_master + 1;
        mask = superPixelGrid==superID;

        if sum(sum(mask)) > 0
            fileExtension = '.png';
            newFileName = strcat('superpixel_',num2str(superID_master),fileExtension);
            rprops = regionprops(mask,'BoundingBox'); %Establish a bounding box
            bbox = rprops.BoundingBox; %surround superpixel with bounding box
                        
            r = im(:,:,1);
            g = im(:,:,2);
            b = im(:,:,3);
            r = r.*uint8(mask);
            g = g.*uint8(mask);
            b = b.*uint8(mask);
            imMasked(:,:,1) = r;
            imMasked(:,:,2) = g;
            imMasked(:,:,3) = b;
            
            imCropped = imcrop(imMasked, bbox); %crop the original image based on this mask  
            col1 = ceil(bbox(1)); row1 = ceil(bbox(2)); 
            col2 = col1+bbox(3); row2 = row1+bbox(4);
            
            newSuperPixel = {superID_master,row1,row2,col1,col2};
            Ttemp = table(newSuperPixel);
            Tnew = [Tnew;Ttemp];
            
            fullDestinationFileName1 = fullfile(outDir, newFileName);
            imwrite(imCropped,char(fullDestinationFileName1));
        end
        perc1 = (superID/maxSuperPixels)*100;     
        waitbar(perc1/100,h1,sprintf('Superpixels Processed: %1.1f%% along...',perc1));
    end
    perc2 = (fileid/totalFiles)*100;
    waitbar(perc2/100,h2,sprintf('Files Processed: %1.1f%% along...',perc2));
end
%save bounding box positions in table
%write table to a text file
disp('Writing superpixel coordinates to text file...');
writetable(Tnew,'SPS_coordinates.txt','Delimiter',',') 
disp('Done!');

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