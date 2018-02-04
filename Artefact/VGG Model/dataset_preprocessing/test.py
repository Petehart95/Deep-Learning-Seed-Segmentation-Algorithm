from keras.preprocessing.image import ImageDataGenerator, array_to_img, img_to_array, load_img
from keras.applications.vgg16 import VGG16, preprocess_input, decode_predictions
from keras.models import Sequential
from keras.layers import Conv2D, MaxPooling2D
from keras.layers import Activation, Dropout, Flatten, Dense
import matplotlib.pyplot as plt
import numpy as np
import os
datagen = ImageDataGenerator(
        rotation_range=40,
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,
        zoom_range=0.2,
        horizontal_flip=True,
        fill_mode='nearest')


dir_path = os.getcwd() 

for image_path in os.listdir(dir_path):
    if image_path == 'test.py' or image_path == 'preview':
        continue
    else:
        print(image_path)
        img = load_img(image_path, target_size=(224,224,3))
        plt.imshow(img)
        plt.show()
        
        x = img_to_array(img)  # this is a Numpy array with shape (3, 150, 150)
        x = x.reshape((1,) + x.shape)  # this is a Numpy array with shape (1, 3, 150, 150)
        
        # the .flow() command below generates batches of randomly transformed images
        # and saves the results to the `preview/` directory
        i = 0
        for batch in datagen.flow(x, batch_size=1,
                                  save_to_dir='preview', save_prefix='seed', save_format='jpg'):
            i += 1
            if i > 20:
                break  # otherwise the generator would loop indefinitely
                
        