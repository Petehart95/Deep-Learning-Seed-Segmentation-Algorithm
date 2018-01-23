% MComp Research Project | Data Preparation - Seed Extraction Script
% for each image in the dataset
%   identify possible seed objects and extract with a bounding box (5px
%   padding)
%   %Save output in a separate image file.

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

objCTR = 1;
h = waitbar(0,'Initializing waitbar...');

for fileid=1:totalFiles % Iterate until processed all selected files
    selectedFile = strcat(pathName,char(fileNames(fileid))); %concatenate selected file and the folder path
    im = imread(selectedFile); % Gather input

    width = 500; % Set a new width size for the image. (Height will be scaled).
    dim = size(im(:,:,:));  
    im = imresize(im,[width*dim(1)/dim(2) width],'bicubic');
    dim = size(im(:,:,:));  

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% PRE-PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    srgb2lab = makecform('srgb2lab');
    lab2srgb = makecform('lab2srgb');

    im_lab = applycform(im, srgb2lab);

    max_luminosity = 100; 
    L = im_lab(:,:,1)/max_luminosity;

    im_adapthisteq = im_lab;
    im_adapthisteq(:,:,1) = adapthisteq(L)*max_luminosity;
    im_adapthisteq = applycform(im_adapthisteq,lab2srgb);

    im_greyscale = im_adapthisteq(:,:,1);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% IMAGE SEGMENTATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    threshold = 254;
    im_bi = rgb2bi(im_greyscale,threshold);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% POST PROCESSING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    im_bi = imfill(im_bi,'holes');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%% OBJECT DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    im_cc = bwconncomp(im_bi);
    im_labelled = labelmatrix(im_cc);

    objectBB = [];
    objectAreas = [];
    topWidth = 0;
    topHeight = 0;
    for x=1:im_cc.NumObjects 
        objectMatrix = [];
        thisWidth = 0;
        thisHeight = 0;
        for i=1:size(im_labelled,1)
            for j=1:size(im_labelled,2)
                if (im_labelled(i,j) == x) 
                    objectMatrix(i,j) = im_bi(i,j);
                end
            end
        end
        %objectMatrices = [objectMatrices objectMatrix];
        
        currentBB = regionprops(objectMatrix,'BoundingBox');

        objectBB = [objectBB currentBB];
        objectAreas = [objectAreas bwarea(objectMatrix)];
        
        currentBB = currentBB.BoundingBox;
        thisHeight = currentBB(:,3);%height
        thisWidth = currentBB(:,4);%height
        
        if thisHeight > topHeight
            topHeight = thisHeight;
        end
        
        if thisWidth > topWidth
            topWidth = thisWidth;
        end
    end
    for k = 1:length(objectBB)
        averageArea = sum(objectAreas) / length(objectAreas);
        thisBB = objectBB(k).BoundingBox;
        im_crop = imcrop(im, thisBB);

        if objectAreas(k) > averageArea
            this_Height = thisBB(:,3);%height
            this_Width = thisBB(:,4);%height
            padWidth = topWidth - this_Width + 1;
            padHeight = topHeight - this_Height + 1;
%             if padWidth > 0 || padHeight > 0
%                 im_crop = padarray(im_crop,[padWidth padHeight],'replicate','both');
%                 %im_crop = imresize(im_crop,[padHeight padWidth]);
%             end
            s = strcat('seed_',num2str(objCTR),'.png');
            imwrite(im_crop,char(s));
            objCTR = objCTR +  1;
        end
    end
    perc = (fileid/totalFiles)*100;
    waitbar(perc/100,h,sprintf('%1.1f%% along...',perc));
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

%end of script