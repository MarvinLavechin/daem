# Dense reconstruction from electron microscope images

## Prerequisites
- Linux or OSX
- Python 2 or Python 3
- CPU or NVIDIA GPU + CUDA CuDNN

## Requirements
- Tensorflow 1.0

## Preferred
- Anaconda Python distribution
- PyCharm

## Getting Started

Clone this repository

```bash
git clone https://github.com/tbullmann/heuhaufen.git
```

Clone other repositories used for computation and visualization if not yet installed

```bash
git clone https://github.com/tbullmann/imagetranslation-tensorflow.git
```

Symlink repositories

```bash
cd heuhaufen
ln -s ../imagetranslation-tensorflow/ imagetranslation
```

Install Tensorflow, e.g. [with Anaconda](https://www.tensorflow.org/install/install_mac#installing_with_anaconda)

Create directories or symlink
```bash
mkdir datasets  # or symlink; for datasets
mkdir temp  # or symlink; for checkpoints, test results
```
Download the VNC dataset
```bash
git clone https://github.com/tbullmann/groundtruth-drosophila-vnc datasets/vnc
```
Combine input and output images
```bash
python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir datasets/vnc/stack1/images/ \
  --b_dir datasets/vnc/stack1/labels/ \
  --output_dir datasets/vnc/combined/
```
Split in training and evaluation set
```bash
python imagetranslation/tools/split.py \
  --dir datasets/vnc/combined
```
Train the model for the direction "AtoB" (EM images to labels):
```bash
python imagetranslation/translate.py  --model pix2pix   --mode train \
  --input_dir datasets/vnc/combined/train \
  --output_dir temp/vnc/train/pix2pix/unet \
  --which_direction AtoB  --max_epochs 200 \
  --display_freq 50
```
Note: this may take 1 hour on GPU, on CPU you will be waiting for a few hours
```bash
tensorboard --logdir temp
```