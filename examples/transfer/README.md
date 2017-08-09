# Transfering paired to unpaired image translation

## Typical result

![Result](Example_transfer_result.jpg)


## Unpaired image to label translation

Directly
```bash
python imagetranslation/translate.py   --mode train \
  --input_dir datasets/cortex/stack1/raw \
  --input_dir_B datasets/vnc/stack1/labels \
  --output_dir temp/Example_transfer/train1 \
  --which_direction AtoB  --Y_loss square \
  --model CycleGAN   --generator resnet \
  --fliplr   --flipud  --transpose \
  --max_epochs 2000  --display_freq 50
```


## Transfer networks from paired to unpaired image to label translation

### Initialize training with paired image to label translation

A single image `49.png` of the mouse SNEMI3D dataset was annotated for membranes, mitochondria and synapses.
This image pair is used for training a pix2pix2 model with residual networks for the G and F generators.
Combine input and output images
```bash
python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir examples/transfer/paired_annotation/raw/ \
  --b_dir examples/transfer/paired_annotation/labels/ \
  --output_dir datasets/cortex/paired_annotation/combined/
```

Train the classifier for the direction "AtoB" (EM images to labels) using bidirectional paired image-to-label translation with a residual net as the generator:
```bash
python imagetranslation/translate.py   --mode train \
  --input_dir datasets/cortex/combined \
  --output_dir temp/Example_transfer/train \
  --which_direction AtoB  --Y_loss square \
  --model pix2pix2   --generator resnet \
  --fliplr   --flipud  --transpose \
  --max_epochs 2000  --display_freq 50
```

*The training may take 1 hour using a GPU, without you will be waiting for a day to finish the training.*

Meanwhile you can follow the training progress using the tensorboard:
```bash
tensorboard --logdir temp/Example_transfer
```

## Continue training with unpaired image to label translation


