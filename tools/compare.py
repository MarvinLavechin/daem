from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from collections import Counter

import os
import argparse
import glob
from sklearn.metrics.cluster import adjusted_rand_score, adjusted_mutual_info_score
import pandas as pd
import numpy as np

from math import log10
from skimage.io import imread
from skimage.measure import label as regions
from scipy.sparse import csr_matrix
from matplotlib import pyplot as plt


def mean_squared_error(imageA, imageB):
    """
    Implements mean squared error between two images
    """
    err = np.sum((imageA.astype("float") - imageB.astype("float")) ** 2) #convert integers to floating point to avoid problems with modulus operations
    err /= float(imageA.shape[0] * imageA.shape[1] * imageA.shape[2])

    return err

def psnr(imageA,imageB):
    """
    Implements peak signal to noise ratio as a measure of similarity for the translation (CycleGAN)
    """
    data_type = imageA.dtype
    number_of_bits = np.dtype(data_type).itemsize*8
    d = 2 ** number_of_bits - 1 #the maximum possible pixel value of the image
    mse = mean_squared_error(imageA,imageB)

    print()
    if (mse != 0):
        return 10*log10(d ** 2 / mse)
    else:
        return float("inf")


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("--inputA", required=True, help="path/files for image A")
    parser.add_argument("--inputB", required=True, help="path/files for image B")
    a = parser.parse_args()

    imageA = imread(a.inputA)
    imageB = imread(a.inputB)

    print("PSNR = %1.3f" % psnr(imageA,imageB))

main()