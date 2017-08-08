#!/usr/bin/env bash

### Prepare datasets
python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir datasets/vnc/stack1/raw/ \
  --b_dir datasets/vnc/stack1/labels/ \
  --output_dir temp/publication/scaling/datasets/combined2

### Copy combined2 to combined1 and scale 50%
### Copy combined2 to combined4 and scale 200%

for i in 1 2 4;
do
	python imagetranslation/tools/split.py \
	--dir temp/publication/scaling/datasets/combined$i
done


### Train
for i in 1 2 4;
do
	python imagetranslation/translate.py  --model pix2pix  --mode train  --generator resnet \
	--output_dir temp/publication/scaling/train/$i \
	--input_dir temp/publication/scaling/datasets/combined$i/train \
    --flipud  --fliplr  --transpose \
	--which_direction AtoB  --Y_loss square \
	--display_freq 100  --max_epochs 300
done

#### Evaluate training
#for i in 1 2 4;
#do
#	bash tools/evaluate.sh temp/publication/scaling/train/$i synapses
#	bash tools/evaluate.sh temp/publication/scaling/train/$i mitochondria
#	bash tools/evaluate.sh temp/publication/scaling/train/$i membranes
#done


### Test and evaluate
for i in 1 2 4;
do
	size=$(echo "2048/$i" | bc)
	python imagetranslation/translate.py   --mode test \
	--checkpoint temp/publication/scaling/train/$i \
	--input_dir temp/publication/scaling/datasets/combined$i/val \
	--output_dir temp/publication/scaling/test/$i \
	  --model pix2pix   --generator resnet \
	  --image_height $size  --image_width $size
done

for i in 1 2 4;
do
	bash tools/evaluate.sh temp/publication/scaling/test/$i synapses
	bash tools/evaluate.sh temp/publication/scaling/test/$i mitochondria
	bash tools/evaluate.sh temp/publication/scaling/test/$i membranes
done


### Accumulate results 
# Using the Python script to link evaluation results in CSV files
pyhton publication/scaling_resolution/aggregate.py












