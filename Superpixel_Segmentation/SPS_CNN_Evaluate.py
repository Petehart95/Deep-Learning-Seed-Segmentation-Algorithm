import tensorflow as tf
import numpy as np
import pylab as plt
import os,cv2
import scipy.misc
import glob
from PIL import Image

currentDirectory = os.getcwd() 
testPath = ('E:\\' + '\\superDataset\\test\\')
checkpointDirectory = (currentDirectory + "\\checkpoint\\")
checkpointName = "seeds-background-model.ckpt.meta"
checkpointFullDirectory = (checkpointDirectory + checkpointName)
outputDirectory = (currentDirectory + "\\output\\")

if not os.path.exists(outputDirectory):
    os.makedirs(outputDirectory)
    
numcols = 1024
numrows = 683

classes = ['seed','background']
num_classes = len(classes)

outputImage = np.zeros((numrows,numcols,int(3)),dtype=np.uint8)

sess = tf.Session()
saver = tf.train.import_meta_graph(checkpointFullDirectory)

saver.restore(sess, "checkpoint/seeds-background-model.ckpt")

graph = tf.get_default_graph()

y_pred = graph.get_tensor_by_name("y_pred:0")

x= graph.get_tensor_by_name("x:0") 
y_true = graph.get_tensor_by_name("y_true:0") 
y_test_images = np.zeros((1, 2)) 

testLabels = []
testPredictions = []
for fields in classes:   
    index = classes.index(fields)
    
    print('Now going to read {} files (Index: {})'.format(fields, index))
    path = os.path.join(testPath, fields, '*g')
    files = glob.glob(path)
    for filePath in files:    
        testLabels.append(index)

        # First, pass the path of the image
        image_size = 20
        num_channels = 3
        images = []
        
        # Reading the image using OpenCV
        bgr_img = cv2.imread(filePath)
        b,g,r = cv2.split(bgr_img)       # get b,g,r
        rgb_img = cv2.merge([r,g,b])     # switch it to rgb    
        
        # Resizing the image to our desired size and preprocessing will be done exactly as done during training
        img = cv2.resize(rgb_img, (image_size, image_size), 0, 0, cv2.INTER_LINEAR)
        img = np.array(img, dtype=np.uint8)
        images.append(img)
        images = np.array(images, dtype=np.uint8)
        images = images.astype('float32')
        images = np.multiply(images, 1.0/255.0) 
        
        # The input to the network is of shape [None image_size image_size num_channels]. Hence we reshape.
        x_batch = images.reshape(1, image_size,image_size,num_channels)
        
        # Creating the feed_dict that is required to be fed to calculate y_pred 
        feed_dict_testing = {x: x_batch, y_true: y_test_images}
        result = sess.run(y_pred, feed_dict=feed_dict_testing)
        
        # if higher probability that this superpixel is a seed
        # result is of this format [probability of seed | probability of background]
        if result[0][0] >= result[0][1]:
            predictedValue = 0
        else:
            predictedValue = 1
            
        testPredictions.append(predictedValue)

#plot the confusion matrix
con = tf.confusion_matrix(testLabels,testPredictions)
sess = tf.Session()
with sess.as_default():
        print(sess.run(con))

        