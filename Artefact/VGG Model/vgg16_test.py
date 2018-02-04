from keras.applications.vgg16 import VGG16, preprocess_input, decode_predictions
from keras.applications.vgg19 import VGG19
from keras.preprocessing.image import load_img, img_to_array, ImageDataGenerator
import matplotlib.pyplot as plt
import numpy as np
import os

model = VGG16(weights='imagenet',include_top=False,input_shape=(224,224,3))
model.summary()

dir_path = os.getcwd()

for image_path in os.listdir(dir_path):
    if image_path == 'vgg16_test.py':
        continue
    else:
        print(image_path)
        image = load_img(image_path, target_size=(224,224,3))
        
        
        plt.imshow(image)
        plt.show()
        image = img_to_array(image)
        image = image.reshape((1,image.shape[0], image.shape[1], image.shape[2]))
        image = preprocess_input(image)
        
        yhat = model.predict(image)
        
        label = decode_predictions(yhat)
        label = label[0][0]
        
        print('%s (%.2f%%)' % (label[1], label[2]*100))
