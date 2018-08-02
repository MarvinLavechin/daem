## Domain adaptation using CycleGAN and its application to microscopy imaging


In this file, we give a short overview of the entire pipeline.
The problem is the following :

<img src="https://github.com/MarvinLavechin/daem/blob/master/examples/transfer/pipeline.png" width="600">

Given 2 stacks of EM images, one from mouse and from drosophila, we want to learn a segmentation algorithm on the mouse stack.
The constraint is that we only have few labels (1 actually) in the mouse stack, while we have 20 labels in the drosophila stack.

Our proposed approach is to use CycleGAN to learn a transfer function which is able to translate mouse images to drosophila images.
By successively applying this transfer function and a classic segmentation algorithm (pre-trained on drosophila), we will be able to provide a segmentation on the mouse images.

Below, you can find a layout of the process of learning a transfer function on unpaired images :

<img src="https://github.com/MarvinLavechin/daem/blob/master/examples/transfer/figure_procedure.png" width="500">