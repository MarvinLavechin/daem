from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import argparse
import glob
from skimage.morphology import skeletonize
from skimage.io import imread
from sklearn.metrics.cluster import adjusted_rand_score, adjusted_mutual_info_score
from scipy.misc import comb
# from scipy.ndimage.morphology import binary_dilation
import numpy as np
import pandas as pd

"""
http://brainiac2.mit.edu/isbi_challenge/evaluation

# Evaluation
In order to evaluate and rank the performances of the participant methods, we first used 2D topology-based segmentation metrics, together with the pixel error (for the sake of metric comparison). Each metric has an updated leader-board. However, retrospective evaluation of the original challenge scoring system revealed that it was not sufficiently robust to variations in the widths of neurite borders. After evaluating all of these metrics and associated variants, we found that specially normalized versions of the Rand error and Variation of Information best matched our qualitative judgements of segmentation quality:

Foreground-restricted Rand Scoring after border thinning: VRand(thinned)
Foreground-restricted Information Theoretic Scoring after border thinning: VInfo (thinned)
We found empirically that of these two popular metrics, VRand is more robust than VInfo  so the new leader board is sorted by its value. You can find all details about the new metrics in our open-access challenge publication.

If you want to apply these metrics yourself to your own results, you can do it within Fiji using this script.

# Dismissed metrics
The old (and deprecated) metrics were:

Minimum Splits and Mergers Warping error, a segmentation metric that penalizes topological disagreements, in this case, the object splits and mergers.
Foreground-restricted Rand error: defined as 1 - the maximal F-score of the foreground-restricted Rand index, a measure of similarity between two clusters or segmentations. On this version of the Rand index we exclude the zero component of the original labels (background pixels of the ground truth).
Pixel error: defined as 1 - the maximal F-score of pixel similarity, or squared Euclidean distance between the original and the result labels.
If you are interested, you can still use this metrics in Fiji with this script.

We understand that segmentation evaluation is an ongoing and sensitive research topic, therefore we open the metrics to discussion. Please, do not hesitate to contact the organizers to discuss about the metric selection.
"""


parser = argparse.ArgumentParser()
parser.add_argument("--predicted", required=True, help="path/files for predicted labels")
parser.add_argument("--true", required=True, help="path/files for predicted labels")
parser.add_argument("--output", required=True, help="output path/files")
parser.add_argument("--threshold", default=0.5, help="threshold for the predict label")
a = parser.parse_args()


def rand_index(truth, predicted):
    """
    Original code by cjauvin, answered Jun 17 '15 at 14:24 on stack exchange
    https://stats.stackexchange.com/questions/89030/rand-index-calculation
    :param truth:
    :param predicted:
    :return:
    """
    tp_plus_fp = comb(np.bincount(truth), 2).sum()
    tp_plus_fn = comb(np.bincount(predicted), 2).sum()
    A = np.c_[(truth, predicted)]
    tp = sum(comb(np.bincount(A[A[:, 0] == i, 1]), 2).sum()
             for i in set(truth))
    fp = tp_plus_fp - tp
    fn = tp_plus_fn - tp
    tn = comb(len(A), 2) - tp - fp - fn
    return (tp + tn) / (tp + fp + fn + tn)


def border_thinning(labels):
    return skeletonize(labels)


def foreground_restriction(truth, predicted):
    # Restrict to pixels where there is no membrane in the ground truth
    keep = np.where(truth==False)
    truth = truth[keep]
    predicted = predicted[keep]
    return truth, predicted


def main():

    dst = []
    output_path = a.output

    pred_paths = sorted(glob.glob(a.predicted))
    true_paths = sorted(glob.glob(a.true))


    for pred_path, true_path in zip(pred_paths, true_paths):

        print ('Evaluate prediction %s vs truth %s' % (pred_path, true_path))

        # load iamges, 0 = black = membrane, 1 = white = non-membrane
        # threshold with default 0.5, so that 1 = membrane/border and 0 is non-membrane/region
        true_border = imread(true_path, as_grey=True) < a.threshold
        pred_border = imread(pred_path, as_grey=True) < a.threshold

        # from matplotlib import pyplot as plt
        #
        # plt.subplot(221)
        # plt.imshow(pred_border)
        # plt.subplot(222)
        # plt.imshow(true_border)

        # border thinning
        pred_border_thinned = border_thinning(pred_border)
        true_border_thinned = border_thinning(true_border)

        # plt.subplot(223)
        # plt.imshow(pred_border_thinned)
        # plt.subplot(224)
        # plt.imshow(true_border_thinned)
        #
        # plt.show()

        # Ravel and restrict to foreground pixels
        true_border, pred_border = foreground_restriction(true_border.ravel(), pred_border.ravel())
        true_border_thinned, pred_border_thinned = foreground_restriction(true_border_thinned.ravel(), pred_border_thinned.ravel())

        RAND = rand_index(true_border, pred_border)
        RAND_thinned = rand_index(true_border_thinned, pred_border_thinned)

        dst.append([pred_path, true_path, RAND, RAND_thinned])

    dst = pd.DataFrame(dst,
                       columns=['pred_path', 'true_path', 'RAND', 'RAND_thinned'])
    dst.to_csv(output_path)

    print ("Saved to %s" % output_path)


main()
