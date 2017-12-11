# Transfering paired to unpaired image translation

Here, we want to learn a transfer function from the mouse raw stack to the drosophila raw stack. Then, applying a supervised algorithm
to predict the label on the translated mouse images.

## Typical result

Work in progress.

## Preparation

Create a directory which contains resized images (in order to reduce the training time).
Then, convert grayscale image to RBG. For instance, using imagemagick :
```bash
cd datasets/cortex/stack1/raw/
mkdir lower_resolution
mogrify -path lower_resolution -resize 50% *.png
cd lower_resolution/
for f in *.png; do convert $f -define png:color-type=2 $f; done

cd ../../../../vnc/stack1/raw/
mkdir lower_resolution
mogrify -path lower_resolution -resize 50% *.png
cd lower_resolution/
for f in *.png; do convert $f -define png:color-type=2 $f; done
```

Split the resized cortex images into training/validation sets. You can use the following command :

```bash
source activate daem
python imagetranslation/tools/split.py \
  --dir datasets/cortex/stack1/raw/lower_resolution
```

or just create your own training/validation sets with few images (to reduce the training time).
If you do that, just be sure that the image 49.png belongs to the validation set. Because, it's the unique cortex image
for which a label exists. Then, we'll apply the transfer function on this image to segment the translated image with a classical supervised algorithm.

Combine the raw images with the target images and create the training/validation sets :
```bash
python imagetranslation/tools/process.py \
--operation combine \
--input_dir datasets/vnc/stack1/raw/ \
--b_dir datasets/vnc/stack1/labels/ \
--output_dir datasets/vnc/combined/

python imagetranslation/tools/split.py   --dir datasets/vnc/combined
```

Resize combined images :
```bash
cd datasets/vnc/combined
mkdir lower_resolution
cp -R train/ lower_resolution/
cp -R val/ lower_resolution/
cd lower_resolution/train
mogrify -resize 50% *.png
for f in *.png; do convert $f -define png:color-type=2 $f; done
cd ../val
mogrify -resize 50% *.png
for f in *.png; do convert $f -define png:color-type=2 $f; done
```

Combine the only labeled image in the cortex dataset and resize it :
```bash
python imagetranslation/tools/process.py  \
--operation combine \
--input_dir examples/transfer1/paired_annotation/raw/ \
--b_dir examples/transfer1/paired_annotation/labels/ \
--output_dir datasets/cortex/paired_annotation/combined/

cd datasets/cortex/paired_annotation/combined/
mogrify -resize 50% 49.png
```

We'll apply the segmentation algorithm on this image later, to compare the segmentation obtained
on the translated image.

Finally, create a resized version of the only label for the mouse image (in order to combine it with the translated image later) :
```bash
mkdir examples/transfer1/paired_annotation/labels/lower_resolution
mogrify -path examples/transfer1/paired_annotation/labels/lower_resolution -resize 50% \
         examples/transfer1/paired_annotation/labels/49.png
```

## Learning the transfer function and applying it. (from mouse raw to drosophila raw)

Directly
```bash
python imagetranslation/translate.py --mode train \
	--input_dir datasets/cortex/stack1/raw/lower_resolution/train \
	--input_dir_B datasets/vnc/stack1/raw/lower_resolution \
	--output_dir temp/Example_Domain_Translation/train \
	--which_direction AtoB --Y_loss square \
	--model CycleGAN --generator resnet \
	--fliplr --flipud --transpose \
	--max_epochs 2000 --display_freq 50

```

Test the model :
```bash
python imagetranslation/translate.py   --mode test \
  --checkpoint temp/Example_Domain_Translation/train \
  --input_dir datasets/cortex/stack1/raw/lower_resolution/val \
  --output_dir temp/Example_Domain_Translation/test \
  --model CycleGAN \
  --image_height 512 --image_width 512 --output_type translation_no_targets
```
*It might take a while to load the model from the checkpoint, but computation is fast even without a GPU.*
The test run will output an HTML file at `temp/Example_Domain_Translation/test/index.html` that shows input/reverse_output/output image sets.

## Segmentation on translated images
###### Train a supervised classifier from drosophila raw to drosophila label.
Train the classifier for the direction "AtoB" (EM images to labels) using paired-to-image translation with a residual net as the generator:
```bash
python imagetranslation/translate.py   --mode train \
  --input_dir datasets/vnc/combined/train \
  --output_dir temp/Example_2D_3Labels/train_lower_resolution \
  --which_direction AtoB  --Y_loss square \
  --model pix2pix   --generator resnet \
  --fliplr   --flipud  --transpose \
  --max_epochs 2000  --display_freq 50
```

###### Apply the classifier on the translated cortex image (fake drosophila image).
