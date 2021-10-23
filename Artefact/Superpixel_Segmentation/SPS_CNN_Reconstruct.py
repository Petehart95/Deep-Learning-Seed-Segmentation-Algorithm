import tensorflow as tf
import numpy as np
import pylab as plt
import os,cv2
import scipy.misc
from PIL import Image

currentDirectory = os.getcwd() 
inputDirectory = (currentDirectory + "\\outputImage_superDataset\\")
checkpointDirectory = (currentDirectory + "\\checkpoint\\")
checkpointName = "seeds-background-model.ckpt.meta"
checkpointFullDirectory = (checkpointDirectory + checkpointName)
outputDirectory = (currentDirectory + "\\output\\")

text_file = np.loadtxt("SPS_coordinates.txt",delimiter=',')
#lines = text_file.read().split(',')

if not os.path.exists(outputDirectory):
    os.makedirs(outputDirectory)

#numrows = len(img)    # 3 rows in your example
#numcols = len(img[0]) # 2 columns in your example
    
numcols = 1024
numrows = 683

outputImage = np.zeros((numrows,numcols,int(3)),dtype=np.uint8)

sess = tf.Session()
saver = tf.train.import_meta_graph(checkpointFullDirectory)

saver.restore(sess, "checkpoint/seeds-background-model.ckpt")

graph = tf.get_default_graph()


y_pred = graph.get_tensor_by_name("y_pred:0")

x= graph.get_tensor_by_name("x:0") 
y_true = graph.get_tensor_by_name("y_true:0") 
y_test_images = np.zeros((1, 2)) 
    
for filePath in os.listdir(inputDirectory): 
    filename = inputDirectory + "\\" + filePath
    # First, pass the path of the image
    image_size = 20
    num_channels = 3
    images = []
    
    # Reading the image using OpenCV
    bgr_img = cv2.imread(filename)
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
        selectedName = os.path.splitext(filePath)[0]
        superpixelNumber = selectedName.split("superpixel_")
        superpixelNumber = int(superpixelNumber[1])
        superpixelPos = text_file[superpixelNumber]
        row1 = int(superpixelPos[1])
        row2 = int(superpixelPos[2])
        col1 = int(superpixelPos[3])
        col2 = int(superpixelPos[4])
        
        #outputImage[row1-1:row2,col1-1:col2] = rgb_img[]
        for x1 in range(0, len(rgb_img)):
            for y1 in range(0, len(rgb_img[0])):
                #print (rgb_img[x1][y1][0] + rgb_img[x1][y1][1] + rgb_img[x1][y1][2])
                if ((rgb_img[x1][y1][0] + rgb_img[x1][y1][1] + rgb_img[x1][y1][2])  > 0):
                    outputImage[row1-1+x1][col1-1+y1][0] = rgb_img[x1][y1][0]
                    outputImage[row1-1+x1][col1-1+y1][1] = rgb_img[x1][y1][1]
                    outputImage[row1-1+x1][col1-1+y1][2] = rgb_img[x1][y1][2]
    #print(filePath)
    #print(result)
    
scipy.misc.toimage(outputImage).save('outfile.jpg')
plt.imshow(outputImage)
#plt.show()

