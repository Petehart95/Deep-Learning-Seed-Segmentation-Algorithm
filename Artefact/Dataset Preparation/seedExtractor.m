% MComp Research Project | Data Preparation - Seed Extraction Script
% for each image in the dataset
%   identify possible seed objects and extract with a bounding box (5px
%   padding)
%   %Save output in a separate image file.

close all; clc; clear; % Reset environment.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% IMAGE ACQUISITION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

selectedFile = 'C:\Users\Peter Hart\Documents\GitHub\MCompResearchProject\Artefact\Dataset Preparation\Images\Capture_00220.jpg';
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
im_BI = rgb2bi(im_greyscale,threshold);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% OBJECT DETECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

im_cc = bwconncomp(im_BI);
im_labelled = labelmatrix(im_cc);

for x=1:im_cc.NumObjects 
    objectMatrix = zeros(size(im_BI));
    for i=1:size(im_labelled,1)
        for j=1:size(I_labelled,2)
            if (im_labelled(i,j) == x) 
                %Find a way to add this object matrix to a vector of
                %objectsgithub
                objectMatrix(i,j) = I_openclose(i,j);
            end
        end
    end
end

st = regionprops(im_BI, 'BoundingBox' );
imshow(im_BI);
hold on;
for k = 1 : length(st)
  thisBB = st(k).BoundingBox;
  rectangle('Position', [thisBB(1),thisBB(2),thisBB(3),thisBB(4)],...
  'EdgeColor','r','LineWidth',2 )
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

% images = {pout, tire, shadow};
% 
% for k = 1:3
%   dim = size(images{k});
%   images{k} = imresize(images{k},[width*dim(1)/dim(2) width],'bicubic');
% end

%end of script