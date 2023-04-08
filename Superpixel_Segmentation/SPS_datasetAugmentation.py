from keras.preprocessing.image import ImageDataGenerator, img_to_array, load_img
import os

#currentDirectory = os.getcwd() 
currentDirectory = 'E:'
inputDirectory1 = (currentDirectory + "\\superDataset\\training\\seed")
inputDirectory2 = (currentDirectory + "\\superDataset\\training\\background")
outputDirectory1 = (currentDirectory + "\\superDataset_augmented\\training\\seed")
outputDirectory2 = (currentDirectory + "\\superDataset_augmented\\training\\background")
className1 = ("seed")
className2 = ("background")
datagen = ImageDataGenerator(rotation_range=40,width_shift_range=0.2,height_shift_range=0.2,shear_range=0.2,zoom_range=0.2,horizontal_flip=True,fill_mode='nearest')

if not os.path.exists(outputDirectory1):
    os.makedirs(outputDirectory1)

if not os.path.exists(outputDirectory2):
    os.makedirs(outputDirectory2)        
    
def normalisation_Augmentation(inputDirectory,outputDirectory,className,datagen):
    totalAugmentations = 4 #total number of augmented results to output (n+1)
    for filePath in os.listdir(inputDirectory): 
        currentFilePath = inputDirectory + "\\" + filePath
        filename, file_extension = os.path.splitext(filePath)

        im = load_img(currentFilePath)
        x = img_to_array(im)  # this is a Numpy array with shape (3, 150, 150)
        x = x.reshape((1,) + x.shape)  # this is a Numpy array with shape (1, 3, 150, 150)
        # the .flow() command below generates batches of randomly transformed images
        # and saves the results to the `preview/` directory
        i = 0
        newSavePrefix = (filename + "_" + str(i))
        for batch in datagen.flow(x,batch_size=1,save_to_dir=outputDirectory,save_prefix=newSavePrefix,save_format='png'):
            newSavePrefix = (filename + "_" + str(i))
            i += 1
            if i > totalAugmentations:
                break  # otherwise the generator would loop indefinitely

print("Augmenting seeds dataset...")
normalisation_Augmentation(inputDirectory1,outputDirectory1,className1,datagen)
print("Augmenting background dataset...")
normalisation_Augmentation(inputDirectory2,outputDirectory2,className2,datagen)

print("Finished!")