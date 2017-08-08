#!/usr/bin/env bash


### Prepare different train/test combinations

python imagetranslation/tools/process.py \
  --operation combine \
  --input_dir datasets/vnc/stack1/raw/ \
  --b_dir datasets/vnc/stack1/labels/ \
  --output_dir datasets/vnc/combined1/

for i in `seq 2 3`;
do
	cp -rf datasets/vnc/combined1/ datasets/vnc/combined$i/
done
for i in `seq 1 3`;
do
	python imagetranslation/tools/split.py \
  	--dir datasets/vnc/combined$i
done



### Train

counter=0

# type image --> hinge loss
for i in `seq 1 3`;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator resnet  --n_res_blocks 9  \
	--output_dir temp/publication/loss_functions/train/$counter \
	--input_dir datasets/vnc/combined$i/train \
	--which_direction AtoB  --Y_loss hinge \
	--display_freq 100  --max_epochs 500
done

for i in `seq 1 3`;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator resnet  --n_res_blocks 9 \
	--output_dir temp/publication/loss_functions/train/$counter \
	--input_dir datasets/vnc/combined$i/train \
	--which_direction AtoB  --Y_loss square \
	--display_freq 100  --max_epochs 500
done

for i in `seq 1 3`;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator resnet  --n_res_blocks 9 \
	--output_dir temp/publication/loss_functions/train/$counter \
	--input_dir datasets/vnc/combined$i/train \
	--which_direction AtoB  --Y_loss softmax \
	--display_freq 100  --max_epochs 500
done

for i in `seq 1 3`;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator resnet  --n_res_blocks 9 \
	--output_dir temp/publication/loss_functions/train/$counter \
	--input_dir datasets/vnc/combined$i/train \
	--which_direction AtoB  --Y_loss approx \
	--display_freq 100  --max_epochs 500
done

for i in `seq 1 3`;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator resnet  --n_res_blocks 9 \
	--output_dir temp/publication/loss_functions/train/$counter \
	--input_dir datasets/vnc/combined$i/train \
	--which_direction AtoB  --Y_loss dice \
	--display_freq 100  --max_epochs 500
done

for i in `seq 1 3`;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator resnet  --n_res_blocks 9 \
	--output_dir temp/publication/loss_functions/train/$counter \
	--input_dir datasets/vnc/combined$i/train \
	--which_direction AtoB  --Y_loss logistic \
	--display_freq 100  --max_epochs 500
done


### Test and evaluate

counter=0
for j in `seq 1 6`;
do
for i in `seq 1 3`;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode test \
	--checkpoint temp/publication/loss_functions/train/$counter \
	--output_dir temp/publication/loss_functions/test/$counter \
	--input_dir datasets/vnc/combined$i/val \
    --image_width 1024  --image_height 1024
	bash tools/evaluate.sh temp/publication/loss_functions/test/$counter synapses
	bash tools/evaluate.sh temp/publication/loss_functions/test/$counter mitochondria
	bash tools/evaluate.sh temp/publication/loss_functions/test/$counter membranes
done
done


### Accumulate results
# Using the Python script to link evaluation results in CSV fules with parameters from JSON files
pyhton publication/loss_functions/aggregate.py








