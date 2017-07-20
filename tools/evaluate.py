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

from skimage.io import imread
from skimage.measure import label as regions
from scipy.sparse import csr_matrix
from matplotlib import pyplot as plt


def segmentation_metrics(true_label, pred_label):

    RAND_label = adjusted_rand_score(true_label.ravel(), pred_label.ravel())
    MI_label = adjusted_mutual_info_score(true_label.ravel(), pred_label.ravel())

    return RAND_label, MI_label


def SNEMI3D_metrics(true_segm, pred_segm):
    n = true_segm.size
    overlap = Counter(zip(true_segm.ravel(), pred_segm.ravel()))
    data = overlap.values()
    row_ind, col_ind = zip(*overlap.keys())
    p_ij = csr_matrix((data, (row_ind, col_ind)))

    a_i = np.array(p_ij[1:, :].sum(axis=1))
    b_j = np.array(p_ij[1:, 1:].sum(axis=0))
    p_i0 = p_ij[1:, 0]
    p_ij = p_ij[1:, 1:]

    sumA = (a_i * a_i).sum()
    sumB = (b_j * b_j).sum() + p_i0.sum()/n
    sumAB = p_ij.multiply(p_ij).sum() + p_i0.sum()/n

    RAND_index = 1 - (sumA + sumB - 2*sumAB) / (n ** 2)
    precision = sumAB / sumB
    recall = sumAB / sumA
    F_score = 2.0 * precision * recall / (precision + recall)
    adapted_RAND_error = 1.0 - F_score

    return RAND_index, precision, recall, F_score, adapted_RAND_error


def test():

    inp_path = '../temp/Example_2D_3Labels/test/images/02-inputs.png'
    pred_path = '../temp/Example_2D_3Labels/test/images/02-outputs.png'
    true_path = '../temp/Example_2D_3Labels/test/images/02-targets.png'

    print ('Evaluate prediction %s vs truth %s' % (pred_path, true_path))

    channel = 0
    threshold = 0.5
    segment_by = 0
    true_label = imread(true_path)[:, :, channel] > threshold
    pred_label = imread(pred_path)[:, :, channel] > threshold

    # scores on labels
    RAND_label, MI_label = segmentation_metrics(true_label, pred_label)
    print("RAND_label = %1.3f, MI_label =%1.3f\n" % (RAND_label, MI_label))

    # scores on segmentation into regions
    true_segm = regions(true_label, background=segment_by)
    pred_segm = regions(pred_label, background=segment_by)
    RAND, precision, recall, F_score, adapted_RAND_error = SNEMI3D_metrics(true_segm, pred_segm)
    print("RAND = %1.3f, precision = %1.3f, recall = %1.3f, F_score = %1.3f, adapted_RAND_error = %1.3f"
          % (RAND, precision, recall, F_score, adapted_RAND_error))

    plt.figure(figsize=(8,5.5))

    plt.subplot(231)
    plt.imshow(imread(inp_path, as_grey=True), cmap='gray')
    plt.title("input")
    plt.axis('off')

    plt.subplot(232)
    plt.imshow(pred_label, cmap='gray')
    plt.title("predicted label")
    plt.axis('off')

    plt.subplot(233)
    plt.imshow(true_label, cmap='gray')
    plt.title("true label")
    plt.axis('off')

    plt.subplot(235)
    plt.imshow(pred_segm)
    plt.title("predicted segmentation")
    plt.axis('off')

    plt.subplot(236)
    plt.imshow(true_segm)
    plt.title("true segmentation")
    plt.axis('off')

    plt.subplots_adjust(left=0.01, right=0.99, top=0.95, bottom=0.01)
    plt.show()


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("--input", default=None, help="path/files for raw images (for plot)")
    parser.add_argument("--predicted", required=True, help="path/files for predicted labels")
    parser.add_argument("--true", required=True, help="path/files for true labels")
    parser.add_argument("--output", required=True, help="output path/files")
    parser.add_argument("--threshold", default=0.5, help="threshold for the predict label")
    parser.add_argument("--channel", type=int, default=0, help="channel to be evaluated")
    parser.add_argument("--segment_by", type=int, default=0, help="border value for segmentation into regions (e.g. membrane)")
    parser.add_argument("--plot", default="nothing", choices=["nothing", "show", "save"])

    a = parser.parse_args()

    dst = []
    output_path = a.output
    def relpath(image_path):
        return os.path.relpath(image_path, os.path.split(output_path)[0])


    inp_paths = sorted(glob.glob(a.input)) if a.input else []
    pred_paths = sorted(glob.glob(a.predicted))
    true_paths = sorted(glob.glob(a.true))


    for index, (inp_path, pred_path, true_path) in enumerate(map(None, inp_paths, pred_paths, true_paths)):

        print ('Evaluate prediction %s vs truth %s' % (pred_path, true_path))

        # load iamges, e.g. 0 = black = membrane, 1 = white = non-membrane
        # threshold with default 0.5, so that 1 = membrane/border and 0 is non-membrane/region
        true_label = imread(true_path)[:, :, a.channel] > a.threshold
        pred_label = imread(pred_path)[:, :, a.channel] > a.threshold

        # scores on labels
        RAND_label, MI_label = segmentation_metrics(true_label, pred_label)
        print("RAND_label = %1.3f, MI_label =%1.3f\n" % (RAND_label, MI_label))

        #scores on segmentation into regions
        true_segm = regions(true_label, background=a.segment_by)
        pred_segm = regions(pred_label, background=a.segment_by)
        RAND, precision, recall, F_score, adapted_RAND_error = SNEMI3D_metrics(true_segm, pred_segm)
        print("RAND = %1.3f, precision = %1.3f, recall = %1.3f, F_score = %1.3f, adapted_RAND_error = %1.3f"
              % (RAND, precision, recall, F_score, adapted_RAND_error))

        dst.append([relpath(pred_path), relpath(true_path), RAND_label, MI_label, RAND, precision, recall, F_score, adapted_RAND_error])

        # plotting
        if not a.plot == "nothing":

            plt.figure(figsize=(8, 5.5))

            if inp_path:
                plt.subplot(231)
                plt.imshow(imread(inp_path, as_grey=True), cmap='gray')
                plt.title("input")
                plt.axis('off')

            plt.subplot(232)
            plt.imshow(pred_label, cmap='gray')
            plt.title("predicted label")
            plt.axis('off')

            plt.subplot(233)
            plt.imshow(true_label, cmap='gray')
            plt.title("true label")
            plt.axis('off')

            plt.subplot(235)
            plt.imshow(pred_segm)
            plt.title("predicted segmentation")
            plt.axis('off')

            plt.subplot(236)
            plt.imshow(true_segm)
            plt.title("true segmentation")
            plt.axis('off')

            plt.subplots_adjust(left=0.01, right=0.99, top=0.95, bottom=0.01)

            if a.plot == "save":
                plt.savefig(output_path+"-sample%d.jpg" % index)
            elif a.plot == "show":
                plt.show()


    dst = pd.DataFrame(dst,
                       columns=['pred_path', 'true_path', 'RAND_label', 'MI_label', 'RAND', 'precision', 'recall', 'F_score', 'adapted_RAND_error'])
    dst['sample'] = dst.index
    dst.to_csv(output_path, index=False)

    print ("Saved to %s" % output_path)


# test()
main()
