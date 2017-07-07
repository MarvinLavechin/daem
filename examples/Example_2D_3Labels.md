# Predicting membrane, mitochondria and synapse labels of the Drosophila 2D dataset by paired image-to-image translation

### Preparation

Combine input and output images
```bash
python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir datasets/vnc/stack1/raw/ \
  --b_dir datasets/vnc/stack1/labels/ \
  --output_dir datasets/vnc/combined/
```
Split in training and evaluation set
```bash
python imagetranslation/tools/split.py \
  --dir datasets/vnc/combined
```

### Training and prediction

Train the classifier for the direction "AtoB" (EM images to labels) using paired-to-image translation with a residual net as the generator:
```bash
python imagetranslation/translate.py   --mode train \
  --input_dir datasets/vnc/combined/train \
  --output_dir temp/Example_2D_3Labels/train \
  --which_direction AtoB  --Y_type label \
  --model pix2pix   --generator resnet \
  --fliplr   --flipud  --transpose \
  --max_epochs 2000  --display_freq 50
```
The `--fliplr   --flipud  --transpose` will provide data augmentation of factor of 8 by randomly rotating and flipping the training samples

The `--display_freq 50` will output an HTML file at `temp/Example_2D_3Labels/train/index.html` that shows input/output/target image sets every 50 steps.

*The training may take 1 hour using a GPU, without you will be waiting for a day to finish the training.*

Meanwhile you can follow the training progress using the tensorboard:
```bash
tensorboard --logdir temp/Example_2D_3Labels
```

Test the model
```bash
python imagetranslation/translate.py   --mode test \
  --checkpoint temp/Example_2D_3Labels/train \
  --input_dir datasets/vnc/combined/val \
  --output_dir temp/Example_2D_3Labels/test \
  --model pix2pix   --generator resnet \
  --image_height 1024  --image_width 1024
```
*It might take a while to load the model from the checkpoint, but computation is fast even without a GPU.*
The test run will output an HTML file at `temp/Example_2D_3Labels/test/index.html` that shows input/output/target image sets.


### Evaluation

Evaluate the model prediction on the four images of the test set:

```bash
python tools/evaluate.py \
  --predicted "temp/Example_2D_3Labels/test/images/*outputs.png" \
  --true "temp/Example_2D_3Labels/test/images/*targets.png" \
  --output temp/Example_2D_3Labels/test/evaluation.csv
```
*Result: Typical mean(standard error) values will be RAND=0.87(0.03) and RANDthinned=0.987(0.001).*
**WARNING: The RAND and RANDthinned are implemented on 1 channel data only, multichannel converted to grayscale. Therefore these values are taken with caution.**

You might want to evaluate the model during the training:
```bash
python tools/evaluate.py \
  --predicted "temp/Example_2D_3Labels/train/images/*outputs.png" \
  --true "temp/Example_2D_3Labels/train/images/*targets.png" \
  --output temp/Example_2D_3Labels/train/evaluation.csv
```

