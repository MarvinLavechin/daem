import numpy as np
from tifffile import imread as tifread
from matplotlib import pyplot as plt
from skimage.measure import label


def label_cytoplasma_and_overlap(data):
    """
    Transform a volume of labels to a stack of two channels. The first channel is the cytoplasma label and the second
    channel is the overlap between adjacent labels.

    Note: This data structure can be used as output image for the GAN.

    Type signature: int (size, image_height, image_width) --> bool (size, image_height, image_width, 2)

    Args:
        data: int (size, image_height, image_width)

    Returns:
        two_channels: bool (size, image_height, image_width, 2)
    """

    sz, sy, sx = data.shape
    two_channels = np.zeros((sz, sy, sx, 2))

    # Channel 0: Cytoplasma
    # If label is not membrane (label == 0)
    # and if label does not change in either y or x direction (without this condition labels touch each other)
    two_channels[:, :, :, 0] = data != 0
    two_channels[:, :-1, :, 0] *= np.diff(data, n=1, axis=1) == 0
    two_channels[:, :, :-1, 0] *= np.diff(data, n=1, axis=2) == 0

    # Channel 1: Overlap of cytoplasma with same label:
    # If label does not change in z direction
    # and if label is cytoplasma
    two_channels[:-1, :, :, 1] = np.diff(data, n=1, axis=0) == 0
    two_channels[:, :, :, 1] *= two_channels[:, :, :, 0]

    two_channels *= 255   # Gray scale values between 0 and 255
    return two_channels


def stack_cytoplasma_and_overlap(two_channels, method='zip'):
    """
    Interleave the two channels in alternating fashing to obtain the following stack of cytoplasma slices and
    connecting slices:

        cytoplasma -> overlap -> cytoplasma -> overlap -> .. -> cytoplasma -> overlap

    Note: The last overlap section is empty.

    Type signature: bool (size, image_height, image_width, 2)  --> bool (2 * size, image_height, image_width)

    Args:
        two_channels: bool (size, image_height, image_width, 2)
        method: (in the result it makes no difference)
                'zip': using zip (default)
                'swapchannels': using numpy.swapaxes (looks better)

    Returns:
        stack: bool (2 * size, image_height, image_width)
    """

    sz, sy, sx, sc = two_channels.shape

    # TODO: Measure which method is faster.

    if method == 'zip':  # (sz, sy, sx, sc)  --> (sz, sc, sy, sx)
        stack = np.array( zip(two_channels[:, :, :, 0], two_channels[:, :, :, 1]) )

    if method == 'swapaxes':  # (sz, sy, sx, sc) --> (sz, sc, sx, sy) --> (sz, sc, sy, sx)
        stack = two_channels.swapaxes(1, 3).swapaxes(2, 3)

    # (sz, sc, sy, sx)  --> (sz * sc, sy, sx)
    stack = np.resize(stack,(2*sz, sy, sx))

    return stack


def relabel_and_slice(stack):
    """
    Relabel the connected components that is the cytoplasma slices and the connecting slices.
    Returns only the cytoplasma labels by discarding the interleaving labelled connecting slices.

                              stack                   relabeled stack         relabel

    cytoplasma section        [ ]  [+]  [+]           [ ]  [1]  [1]
                                    :                       :
    overlap section           [ ]  [+]  [ ]           [ ]  [1]  [ ]           [ ]  [1]  [1]    relabel section
                                    |                       |                       :
    cytoplasma section        [+]--[+]--[ ]     -->   [1]--[1]--[ ]     -->   [1]--[1]--[ ]    relabel section
                                    |                       |                       :
    overlap section           [ ]  [ ]  [ ]           [ ]  [ ]  [ ]           [ ]  [2]  [2]    relabel section
                                    :                       :
    cytoplasma section        [ ]  [+]  [+]           [ ]  [2]  [2]


    Note: Only orthogonal connected voxels are treated as a neighbor (1-connectivity).
    See: http://scikit-image.org/docs/dev/api/skimage.measure.html#skimage.measure.label

    Type signature: bool (2 * size, image_height, image_width) --> int (size, image_height, image_width)

    Args:
        stack: bool (2 * size, image_height, image_width)

    Returns:
        relabel: int (size, image_height, image_width)

    """
    relabel = label(stack, connectivity=1)
    relabel = relabel [0::2]
    return relabel


def test_relabeling():
    # Test conversion of three dimensional region labelling into cytoplasma and overlap and reconstruction from that
    # TODO Prediction of cytoplasma (membranes) and overlap from (adjacent) EM images

    # Get 3D dataset as multi tiff file
    # TODO Load from series of png images (!)
    filename = 'cortex/temp/train-labels.tif'
    data = tifread('../datasets/' + filename)

    plt.subplot(241)
    plt.imshow(data[0])
    plt.title('label [z=0,:,:]')
    plt.subplot(245)
    plt.imshow(data[1])
    plt.title('label [z=1,:,:]')
    two_channels = label_cytoplasma_and_overlap(data)
    plt.subplot(242)
    plt.imshow(two_channels[0, :, :, 0])
    plt.title('cytoplasma [z=0,:,:]')
    plt.subplot(246)
    plt.imshow(two_channels[0, :, :, 1])
    plt.title('overlap [z=0,:,:]')
    stack = stack_cytoplasma_and_overlap(two_channels)
    plt.subplot(243)
    plt.imshow(stack[0, :, :])
    plt.title('stack [z=0,:,:]')
    plt.subplot(247)
    plt.imshow(stack[1, :, :])
    plt.title('stack [z=0+1/2,:,:]')
    relabel = relabel_and_slice(stack)
    plt.subplot(244)
    plt.imshow(relabel[0, :, :])
    plt.title('relabel [z=0,:,:]')
    plt.subplot(248)
    plt.imshow(relabel[1, :, :])
    plt.title('relabel [z=1,:,:]')
    plt.show()


if __name__ == '__main__':
    test_relabeling()


