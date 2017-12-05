# Transfering paired to unpaired image translation

Here, we want to learn a transfer function from the mouse raw stack to the drosophila raw stack. Then, applying a supervised algorithm
to predict the label on the translated mouse images.

## Typical result

Work in progress.

## Preparation

Convert grayscale image to RBG using imagemagick or FIJI.

Create a directory which contains resized images (in order to reduce the training time), for instance using imagemagick :
```bash
cd datasets/cortex/stack1/raw
mkdir lower_resolution
mogrify -path lower_resolution -resize 50% *.png

cd ../../../vnc/stack1/raw
mkdir lower_resolution
mogrify -path lower_resolution -resize 50% *.png
```

Split the resized cortex images into training/validation sets. You can use the following command :

```bash
python imagetranslation/tools/split.py \
  --dir datasets/cortex/stack1/raw/lower_resolution
```

or just create your own training/validation sets with few images (to reduce the training time).

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
  --image_height 512 --image_width 512
```
*It might take a while to load the model from the checkpoint, but computation is fast even without a GPU.*
The test run will output an HTML file at `temp/Example_Domain_Translation/test/index.html` that shows input/reverse_output/output/target image sets.

## Segmentation on translated images

Work in progress.
