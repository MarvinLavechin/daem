#!/bin/bash

NUMBER_OF_JOBS=$1

for l in 1 10 100 100; do
    for (( c=1; c<=$NUMBER_OF_JOBS; c++ ))
    do
        sbatch -p gpucpuM train_apply_cycleGAN_rawraw.sh --checkpoint_segmentation temp/Example_2D_3Labels/train_on_cropped --max_epochs 1000 --weight_segmentation $l --generator unet --u_depth 2 --random_seed_mode
        sleep 1
    done
done

