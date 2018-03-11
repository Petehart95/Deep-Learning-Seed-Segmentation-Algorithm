from keras.preprocessing.image import ImageDataGenerator, img_to_array, load_img
import os

currentDirectory = os.getcwd() 
inputDirectory1 = (currentDirectory + "\\dataset\\training\\seed")
inputDirectory2 = (currentDirectory + "\\dataset\\training\\background")
outputDirectory1 = (currentDirectory + "\\dataset_normalised\\training\\seed")
outputDirectory2 = (currentDirectory + "\\dataset_normalised\\training\\background")
className1 = ("seed")
className2 = ("background")
datagen = ImageDataGenerator(rotation_range=40,width_shift_range=0.2,height_shift_range=0.2,shear_range=0.2,zoom_range=0.2,horizontal_flip=True,fill_mode='nearest')

if not os.path.exists(outputDirectory1):
    os.makedirs(outputDirectory1)

if not os.path.exists(outputDirectory2):
    os.makedirs(outputDirectory2)        
    
def normalisation_Augmentation(inputDirectory,outputDirectory,className,datagen):
    totalAugmentations = 20 #total number of augmented results to output
    n = 20 #normalised size
    for filePath in os.listdir(inputDirectory): 
        currentFilePath = inputDirectory + "\\" + filePath
        im = load_img(currentFilePath, target_size=(n,n,3))
        x = img_to_array(im)  # this is a Numpy array with shape (3, 150, 150)
        x = x.reshape((1,) + x.shape)  # this is a Numpy array with shape (1, 3, 150, 150)
        # the .flow() command below generates batches of randomly transformed images
        # and saves the results to the `preview/` directory
        i = 0
        for batch in datagen.flow(x,batch_size=1,save_to_dir=outputDirectory,save_prefix=className,save_format='jpeg'):
            i += 1
            if i > totalAugmentations:
                break  # otherwise the generator would loop indefinitely
            
normalisation_Augmentation(inputDirectory1,outputDirectory1,className1,datagen)
normalisation_Augmentation(inputDirectory2,outputDirectory2,className2,datagen)

print("Finished!")