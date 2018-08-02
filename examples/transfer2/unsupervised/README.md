# Domain adaptation using unsupervised CycleGAN

Here, we want to learn a transfer function from the mouse raw stack to the drosophila raw stack. 
Then, we want to apply a (supervised) classification algorithm to predict the label on the translated mouse images.
The transfer function will be learned using unsupervised CycleGAN, that is without using any labels from the mouse stack.

## Typical result

Work in progress.

## Learning the transfer function (from mouse raw images to drosophila raw images), then applying it.

We want to use all of the raw images that we have, there is no need to have a train set and a test set.
However, we recommend to delete some of the drosophila images to reduce the memory usage and decrease the training time.
We haven't observed any improvements in the segmentation accuracy and/or in the quality of the transfer by using 80 drosophila raw images rather than 20 well-chosen ones (sufficiently different).

```bash
python imagetranslation/translate.py --mode train \
	--input_dir datasets/cropped_cortex/stack1/raw \
	--input_dir_B datasets/cropped_vnc/stack1/raw \
	--output_dir temp/Example_Domain_Adaptation_Unsupervised/train_domain_adaptation \
	--which_direction AtoB --Y_loss square \
	--model CycleGAN --generator resnet \
	--fliplr --flipud --transpose \
	--max_epochs 2000 --display_freq 50
```

We apply the transfer on our mouse test set :

```bash
python imagetranslation/translate.py   --mode test \
  --checkpoint temp/Example_Domain_Adaptation_Unsupervised/train_domain_adaptation \
  --input_dir datasets/cropped_cortex/combined/val \
  --output_dir temp/Example_Domain_Adaptation_Unsupervised/test_domain_adaptation \
  --model CycleGAN \
  --image_height 512 --image_width 512
```

*It might take a while to load the model from the checkpoint, but computation is fast even without a GPU.*
The test run will output an HTML file at `temp/Example_Domain_Adaptation_Unsupervised/test_domain_adaptation/index.html` that shows input/reverse_output/output/target images.

## Segmenting the translated images
###### Training a supervised classifier from drosophila raw images to drosophila labels.

Train the classifier for the direction "AtoB" (EM images to labels) using paired-to-image translation with a residual net as the generator:
(Note that this step can be skipped if you already trained a classifier on the cropped images)

```bash
python imagetranslation/translate.py   --mode train \
  --input_dir datasets/cropped_vnc/combined/train \
  --output_dir temp/Example_2D_3Labels/train_on_cropped \
  --which_direction AtoB  --Y_loss square \
  --model pix2pix   --generator resnet \
  --fliplr   --flipud  --transpose \
  --max_epochs 2000  --display_freq 50
```

###### Applying the classifier on the translated cortex images (equivalently called fake drosophila images).

First, we need to build the pairs (fake image)/(true label) :

```bash
TRANSLATED_LABEL_DIR=temp/Example_Domain_Adaptation_Unsupervised/translated_images/translated;

mkdir -p temp/Example_Domain_Adaptation_Unsupervised/translated_images/translated;
cp temp/Example_Domain_Adaptation_Unsupervised/test_domain_adaptation/images/*-outputs.png $TRANSLATED_LABEL_DIR;
rename 's/-outputs//' $TRANSLATED_LABEL_DIR/*-outputs.png;
python imagetranslation/tools/process.py  \
--operation combine \
--input_dir $TRANSLATED_LABEL_DIR \
--b_dir datasets/cropped_cortex/stack1/labels/ \
--output_dir $TRANSLATED_LABEL_DIR/paired_annotation/;
rename 's/.png/_translated.png/' $TRANSLATED_LABEL_DIR/paired_annotation/*.png;
```

Then, we can apply the classifier on these image/label pairs :

```bash
python imagetranslation/translate.py   --mode test \
  --checkpoint temp/Example_2D_3Labels/train_on_cropped \
  --input_dir temp/Example_Domain_Adaptation_Unsupervised/translated_images/translated/paired_annotation/ \
  --output_dir temp/Example_Domain_Adaptation_Unsupervised/test_domain_adaptation_segmentation \
  --image_height 512  --image_width 512 --model pix2pix --seed 0
```

Note that the last step will generate a report named **_test_domain_adaptation_segmentation/test/index.html_** which provides :
- the input that is the fake drosophila image
- the output that is the segmentation obtained on the fake image
- the target that is the groundtruth of the real mouse image (before transfer by CycleGAN)

###### Evaluating the results

Evaluate the model prediction for each channel :

```bash
FOLDER_TEST_DA_SEG=temp/Example_Domain_Adaptation_Unsupervised/test_domain_adaptation_segmentation;
EVAL_PREDICTED_DIR=$FOLDER_TEST_DA_SEG/images/*_translated-outputs.png;
EVAL_TRUE_DIR=$FOLDER_TEST_DA_SEG/images/*_translated-targets.png;


python tools/evaluate.py --predicted $EVAL_PREDICTED_DIR \
--true $EVAL_TRUE_DIR \
--output $FOLDER_TEST_DA_SEG/evaluation-synapses.csv  --channel 0;

python tools/evaluate.py --predicted $EVAL_PREDICTED_DIR \
--true $EVAL_TRUE_DIR \
--output $FOLDER_TEST_DA_SEG/evaluation-mitochondria.csv  --channel 1;

python tools/evaluate.py --predicted $EVAL_PREDICTED_DIR \
--true $EVAL_TRUE_DIR \
--output $FOLDER_TEST_DA_SEG/evaluation-membranes.csv  --channel 2 --segment_by 1
```

This step will generate three metric reports in the directory **_test_domain_adaptation_segmentation_**.