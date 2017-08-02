#!/usr/bin/env bash

### Prepare datasets
python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir datasets/vnc/stack1/raw/ \
  --b_dir datasets/vnc/stack1/labels/ \
  --output_dir temp/publication/scaling/datasets/combined2

for i in 1 2 3 4;
do
	python imagetranslation/tools/split.py \
	--dir temp/publication/scaling/datasets/combined$i
done


### Train
for i in 1 2 3 4;
do
	python imagetranslation/translate.py  --model pix2pix  --mode train  --generator resnet \
	--output_dir temp/publication/scaling/train/$i \
	--input_dir temp/publication/scaling/datasets/combined$i/train \
    --flipud  --fliplr  --transpose \
	--which_direction AtoB  --Y_loss square \
	--display_freq 100  --max_epochs 300
done

### Evaluate training
for i in 1 2 3 4;
do
	bash tools/evaluate.sh temp/publication/scaling/train/$i synapses
	bash tools/evaluate.sh temp/publication/scaling/train/$i mitochondria
	bash tools/evaluate.sh temp/publication/scaling/train/$i membranes
done


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

# NOTE: Information about generator type / depath can be obtained by order of files only

sed -n 1p temp/publication/scaling/test/1/evaluation/membranes.csv > temp/publication/scaling/evaluation-membranes.csv
sed -n 1p temp/publication/scaling/test/1/evaluation/mitochondria.csv > temp/publication/scaling/evaluation-mitochondria.csv
sed -n 1p temp/publication/scaling/test/1/evaluation/synapses.csv > temp/publication/scaling/evaluation-synapses.csv
for i in 1 2 4;
do
	sed 1d temp/publication/scaling/test/$i/evaluation/membranes.csv >> temp/publication/scaling/evaluation-membranes.csv
	sed 1d temp/publication/scaling/test/$i/evaluation/mitochondria.csv >> temp/publication/scaling/evaluation-mitochondria.csv
	sed 1d temp/publication/scaling/test/$i/evaluation/synapses.csv >> temp/publication/scaling/evaluation-synapses.csv
done
















