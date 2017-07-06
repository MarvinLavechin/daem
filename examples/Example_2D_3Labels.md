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

Train the model for the direction "AtoB" (EM images to labels):
```bash
python imagetranslation/translate.py  --model pix2pix   --mode train \
  --input_dir datasets/vnc/combined/train \
  --output_dir temp/Example_2D_3Labels/train \
  --which_direction AtoB  --max_epochs 200 \
  --display_freq 50
```
Note: this may take 1 hour on GPU, on CPU you will be waiting for a few hours
```bash
tensorboard --logdir temp/Example_2D_3Labels
```

Test the model
```bash
python translate.py \
  --model pix2pix \
  --mode test \
  --output_dir temp/Example_2D_3Labels/test \
  --input_dir datasets/facades/val \
  --checkpoint temp/Example_2D_3Labels/train
```
The test run will output an HTML file at `temp/facades_test/index.html` that shows input/output/target image sets.


### Evaluation

Evaluate the model prediction on the test set:

```bash
python tools/evaluate.py \
  --predicted "temp/Example_2D_3Labels/test/images/*outputs.png" \
  --true "datasets/facades/val/*.png" \
  --output temp/Example_2D_3Labels/test/evaluation.csv
```

You might want to evaluate the model during the training:
```bash
python tools/evaluate.py \
  --predicted "temp/Example_2D_3Labels/train/images/*outputs.png" \
  --true "temp/Example_2D_3Labels/train/images/*targets.png" \
  --output temp/Example_2D_3Labels/train/evaluation.csv
```

