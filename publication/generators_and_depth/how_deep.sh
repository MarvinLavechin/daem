#!/usr/bin/env bash


### Train

counter=0

for n_depth in 4 5 6 7 8;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator unet  --u_depth $n_depth  \
	--output_dir temp/publication/how_deep/train/$counter \
	--input_dir datasets/vnc/combined/train \
	--which_direction AtoB  --Y_type label \
	--display_freq 100  --max_epochs 500
done 

for n_dense_blocks in 1 2 3 4 5;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator densenet  --n_dense_blocks $n_dense_blocks  \
	--output_dir temp/publication/how_deep/train/$counter \
	--input_dir datasets/vnc/combined/train \
	--which_direction AtoB  --Y_type label \
	--display_freq 100  --max_epochs 500
done

for n_highway_units in 4 6 9 12 16;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator highwaynet  --n_highway_units $n_highway_units  \
	--output_dir temp/publication/how_deep/train/$counter \
	--input_dir datasets/vnc/combined/train \
	--which_direction AtoB  --Y_type label \
	--display_freq 100  --max_epochs 500
done

for n_res_blocks in 4 6 9 12 16;
do
	((counter++))
	python imagetranslation/translate.py  --model pix2pix  --mode train \
	--generator resnet  --n_res_blocks $n_res_blocks \
	--output_dir temp/publication/how_deep/train/$counter \
	--input_dir datasets/vnc/combined/train \
	--which_direction AtoB  --Y_type label \
	--display_freq 100  --max_epochs 500
done


### Test and evaluate

for i in `seq 1 $counter`;
do
	python imagetranslation/translate.py  --model pix2pix  --mode test \
	--checkpoint temp/publication/how_deep/train/$i \
	--output_dir temp/publication/how_deep/test/$i \
	--input_dir datasets/vnc/combined/val \
    --image_width 1024  --image_height 1024 
	bash tools/evaluate.sh temp/publication/how_deep/test/$i synapses
	bash tools/evaluate.sh temp/publication/how_deep/test/$i mitochondria
	bash tools/evaluate.sh temp/publication/how_deep/test/$i membranes
done


### Accumulate results 

# Using the Python script to link evaluation results in CSV fules with parameters from JSON files
pyhton publication/how_deep/aggregate.py


# NOTE: Information about generator type / depath can be obtained by order of files only
#sed -n 1p temp/publication/how_deep/test/1/evaluation/membranes.csv > temp/publication/how_deep/evaluation-membranes.csv
#sed -n 1p temp/publication/how_deep/test/1/evaluation/mitochondria.csv > temp/publication/how_deep/evaluation-mitochondria.csv
#sed -n 1p temp/publication/how_deep/test/1/evaluation/synapses.csv > temp/publication/how_deep/evaluation-synapses.csv
#for i in `seq 1 $counter`;
#do
#	sed 1d temp/publication/how_deep/test/$i/evaluation/membranes.csv >> temp/publication/how_deep/evaluation-membranes.csv
#	sed 1d temp/publication/how_deep/test/$i/evaluation/mitochondria.csv >> temp/publication/how_deep/evaluation-mitochondria.csv
#	sed 1d temp/publication/how_deep/test/$i/evaluation/synapses.csv >> temp/publication/how_deep/evaluation-synapses.csv
#done




