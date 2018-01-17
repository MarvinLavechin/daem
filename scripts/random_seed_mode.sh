#!/bin/bash

NUMBER_OF_JOBS=$1

for (( n=1; n<=8; n++))
do
	for (( c=1; c<=$NUMBER_OF_JOBS; c++ ))
	do
		sbatch -p gpucpuM train_apply_cycleGAN_rawraw.sh --generator unet --u_depth $n --max_epochs 1000 --random_seed_mode
		sleep 1
	done
done
