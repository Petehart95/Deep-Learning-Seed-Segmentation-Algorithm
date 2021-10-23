% MComp Research Project | Superpixel Segmentation Script

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


currentDir = pwd;
outDir = 'E:\';
trainOutDir1 = strcat(outDir,'\superDataset\training\seed');
trainOutDir2 = strcat(outDir,'\superDataset\training\background');
testOutDir1 = strcat(outDir,'\superDataset\test\seed');
testOutDir2 = strcat(outDir,'\superDataset\test\background');
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
if ~exist(trainOutDir1,'dir')
    mkdir(trainOutDir1);
end

if ~exist(trainOutDir2,'dir')
    mkdir(trainOutDir2);
end

if ~exist(testOutDir1,'dir')
    mkdir(testOutDir1);
end

if ~exist(testOutDir2,'dir')
    mkdir(testOutDir2);
end

superID_master = 0;
row1 = [];row2 = [];col1 = []; col2 = [];
newSuperPixel = {superID_master,row1,row2,col1,col2};


totalFiles = length(fileNames); % Store total count for how many files are going to be processed.
totalMasks = length(maskFileNames);

p = 0.8;      % proportion of rows to select for training
tf = false(totalFiles,1);    % create logical index vector
tf(1:round(p*totalFiles)) = true;     
tf = tf(randperm(totalFiles));   % randomise order

dataTraining = fileNames(:,tf); 
totalTrainingFiles = size(dataTraining,2);
dataTest = fileNames(:,~tf);
totalTestFiles = size(dataTest,2);
superID_master = 0;

selectedTestDate = {dataTest};
selectedTestDateTable = table(selectedTestDate);
writetable(selectedTestDateTable,'testImages.txt','Delimiter',',') 

disp('Preparing training dataset...');
prepareDataset(totalTrainingFiles,dataTraining,pathName,trainOutDir1,trainOutDir2, superID_master);
disp('Preparing test dataset...');
prepareDataset(totalTestFiles,dataTest,pathName,testOutDir1,testOutDir2, superID_master);

function prepareDataset(totalFiles, fileNames, pathName, outDir1,outDir2, superID_master)
    currentDir = pwd;    
    maskDir = strcat(currentDir,'\maskDataset');

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
        %imSuperMask = boundarymask(superPixelGrid); %Full image superpixel segmentation mask
        %imshow(imoverlay(im,imSuperMask,'red'),'InitialMagnification',67);
        for superID=1:maxSuperPixels %Iterate through the entire grid of superpixels
            superID_master = superID_master + 1;
            superMask = false(numRows,numCols); %Reset mask
            superMask = superPixelGrid == superID;

            r = im(:,:,1);
            g = im(:,:,2);
            b = im(:,:,3);
            r = r.*uint8(superMask);
            g = g.*uint8(superMask);
            b = b.*uint8(superMask);
            imMasked(:,:,1) = r;
            imMasked(:,:,2) = g;
            imMasked(:,:,3) = b;
            
           if sum(sum(superMask)) > 0
                fileExtension = '.png';
                newFileName = strcat('superpixel_',num2str(superID_master),fileExtension);
                rprops = regionprops(superMask,'BoundingBox'); %Establish a bounding box
                bbox = rprops.BoundingBox; %surround superpixel with bounding box
                imCropped = imcrop(imMasked, bbox); %crop the original image based on this mask  
                maskOverlay = imcrop(imMask, bbox);     

                if max(maskOverlay) > 0 %if seed
                    fullDestinationFileName1 = fullfile(outDir1, newFileName);
                    imwrite(imCropped,char(fullDestinationFileName1));
                else
                    fullDestinationFileName1 = fullfile(outDir2, newFileName);
                    imwrite(imCropped,char(fullDestinationFileName1));
                end
            end
            perc1 = (superID/maxSuperPixels)*100;
            waitbar(perc1/100,h1,sprintf('Superpixels Processed: %1.1f%% along...',perc1));
        end
        perc2 = (fileid/totalFiles)*100;
        waitbar(perc2/100,h2,sprintf('Files Processed: %1.1f%% along...',perc2));
    end
    disp('Done!');
    close(h1);
    close(h2); %terminate progress bars
end



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