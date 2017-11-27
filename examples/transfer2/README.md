# Transfering paired to unpaired image translation

Here, we want to learn a transfer function from the mouse raw stack to the drosophila raw stack. Then, applying a supervised algorithm
to predict the label on the translated mouse images.

## Typical result

Work in progress.

## Preparation

Convert grayscale image to RBG using imagemagick or FIJI.

## Learning the transfer function and applying it. (from mouse raw to drosophila raw)

Directly
```bash
python imagetranslation/translate.py --mode train \
	--input_dir datasets/cortex/stack1/raw/val \
	--input_dir_B datasets/vnc/stack1/raw \
	--output_dir temp/Example_Domain_Translation/train \
	--which_direction AtoB --Y_loss square \ 
	--model CycleGAN --generator resnet \ 
	--fliplr --flipud --transpose \ 
	--max_epochs 2000 --display_freq 50

```

The training may take 1 day using a GPU.

Test the model :
```bash
python imagetranslation/translate.py   --mode test \
  --checkpoint temp/Example_Domain_Translation/train \
  --input_dir datasets/cortex/stack1/val \
  --output_dir temp/Example_Domain_Translation/test \
  --image_height 1024  --image_width 1024
```
*It might take a while to load the model from the checkpoint, but computation is fast even without a GPU.*
The test run will output an HTML file at `temp/Example_Domain_Translation/test/index.html` that shows input/reverse_output/output/target image sets.

## Segmentation on translated images

Work in progress.
