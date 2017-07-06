from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import pandas as pd
import argparse
import os
import threading
import time
import glob
import warnings
import shutil

from skimage.segmentation import clear_border
from skimage.measure import label, regionprops
from skimage.morphology import closing, square
from skimage.io import imread, imsave

import multiprocessing

parser = argparse.ArgumentParser()
parser.add_argument("--input_dir", required=True, help="path to folder containing images")
parser.add_argument("--output_dir", required=True, help="output path")
parser.add_argument("--operation", required=True, choices=["features", "contours", "labels"])
parser.add_argument("--workers", type=int, default=1, help="number of workers")
# features
parser.add_argument("--min_area", default=10, help="minimal area (in pixels) for a region to be considered for feature extraction")

a = parser.parse_args()


def features(src):
    """
    Convert label image into regions and return a decription of their features.
    :param src: source image
    :return: dataframe containing the features
    """

    # apply threshold
    bw = closing(src > 0, square(3))

    # remove artifacts connected to image border
    cleared = clear_border(bw)

    # label image regions
    label_image = label(cleared)

    dst = []
    for region in regionprops(label_image):

        area = region.area

        # take regions with large enough areas
        if area >= a.min_area:

            # Features
            y0, x0 = region.centroid
            orientation = region.orientation
            length = region.major_axis_length
            width = region.minor_axis_length
            minr, minc, maxr, maxc = region.bbox

            dst.append([area, y0, x0, orientation, length, width, minr, minc, maxr, maxc])

    dst = pd.DataFrame(dst,
                       columns=['area', 'y0', 'x0', 'orientation', 'length', 'width', 'minr', 'minc', 'maxr', 'maxc'])

    return dst


def process(src_path):
    if a.operation == "features":
        """
        Extract features for registration to and save dataframe as csv file.
        """
        name, _ = os.path.splitext(os.path.basename(src_path))
        dst_path = os.path.join(a.output_dir, name + ".csv")
        src = imread(src_path)
        dst = features(src)
        dst.to_csv(dst_path)

    else:
        raise Exception("invalid operation")


def save_image_to_sub_dir(image, base_dir, sub_dir, basename, ext=".png"):
    full_dir = os.path.join(base_dir, sub_dir)
    if not os.path.exists(full_dir):
        os.makedirs(full_dir)
    full_path = os.path.join(full_dir, basename+ext)
    with warnings.catch_warnings():  # suppress "low contrast image" warning while saving 16bit png with labels
        warnings.simplefilter("ignore")
        imsave (full_path, image)


complete_lock = threading.Lock()
start = None
num_complete = 0
total = 0

def complete():
    global num_complete, rate, last_complete

    num_complete += 1
    now = time.time()
    elapsed = now - start
    rate = num_complete / elapsed
    if rate > 0:
        remaining = (total - num_complete) / rate
    else:
        remaining = 0

    print("%d/%d complete  %0.2f images/sec  %dm%ds elapsed  %dm%ds remaining" % (num_complete, total, rate, elapsed // 60, elapsed % 60, remaining // 60, remaining % 60))

    last_complete = now


def main():
    if not os.path.exists(a.output_dir):
        os.makedirs(a.output_dir)

    # Get all files if input_dir contains a wildcard
    if "*" in a.input_dir[-1]:
        src_paths = glob.glob(a.input_dir)
    # Get all files within the directory input_dir, or all files that start with input_dir
    # Note: if input_dir is a directory adding a "*" will get all files within this directory without recursion
    else:
        src_paths = glob.glob(a.input_dir+"*")

    global total
    total = len(src_paths)
    
    print("processing %d files" % total)

    global start
    start = time.time()

    if a.workers == 1:
        for args in src_paths:
            process(args)
            complete()
    else:
        pool = multiprocessing.Pool(a.workers)
        for result in pool.imap_unordered(process, src_paths):
            complete()

main()
