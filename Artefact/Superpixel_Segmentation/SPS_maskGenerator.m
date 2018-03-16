 % MComp Research Project | Superpixel Segmentation Script

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the current directory
currentdir = pwd;
outDir = strcat(currentdir,'\maskDataset');

% Dialog box for file selection (filter = .jpg,.png)
[fileNames, pathName, filterIndex] = uigetfile({'*.jpg;*.png;','All Image Files';'*.*','All Files'},'Select Input Images...','MultiSelect', 'on');

% Check if only one file is selected
if ~iscell(fileNames)
    fileNames = {fileNames}; % If only one file is selected, ensure the file name is cell and not character
end 
totalFiles = size(fileNames,2); % Store total count for how many files are going to be processed.

%Check if the output directories exist, if not then make them.
if ~exist(outDir,'dir')
    mkdir(outDir);
end

if totalFiles > 0
    h = waitbar(0,'Files Processed: 0% along...');
end

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
    
    %newFileName = strcat('seedmask_',num2str(fileid),'.jpeg');
    newFileName = fileNames(fileid);
    newFileName = erase(newFileName,'.jpg');
    newFileName = strcat(newFileName,'.png');
    fullDestinationFileName = fullfile(outDir, newFileName);
    imwrite(Iout,char(fullDestinationFileName));
    
    perc = (fileid/totalFiles)*100;
    waitbar(perc/100,h,sprintf('Files Processed: %1.1f%% along...',perc));
end

close(h); %terminate progress bar

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