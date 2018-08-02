# Data preparation for domain adaptation

Before running CycleGAN on the different scenarios, we need to prepare our data.

We will use the only mouse image which has been annotated : `49.png`

First, we create the label folder of the mouse stack :

```bash
mkdir datasets/cortex/stack1/labels
cp examples/transfer/paired_annotation/labels/49.png datasets/cortex/stack1/labels
```

Next, we combine pair images :

```bash
python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir examples/transfer/paired_annotation/raw/ \
  --b_dir examples/transfer/paired_annotation/labels/ \
  --output_dir datasets/cortex/paired_annotation/combined/
```

Since we have just one annotated mouse image, we create a new version of the drosophila and the mouse stack by cropping them by 4.
In that way, we will be able to have a mouse train set and a mouse test set to evaluate the segmentation accuracy :

```bash
python imagetranslation/tools/crop_images.py
```

We combine mouse cropped pair images :

```bash
python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir datasets/cropped_cortex/stack1/raw \
  --b_dir datasets/cropped_cortex/stack1/labels \
  --output_dir datasets/cropped_cortex/combined/
```

Then, we do the same for drosophila cropped images :

```bash
python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir datasets/cropped_vnc/stack1/raw \
  --b_dir datasets/cropped_vnc/stack1/labels \
  --output_dir datasets/cropped_vnc/combined/
```

Finally, we divide our two datasets into a train set and a test set : 

```bash
python imagetranslation/tools/split.py \
  --dir datasets/cropped_vnc/combined;
python imagetranslation/tools/split.py \
  --dir datasets/cropped_cortex/combined
```