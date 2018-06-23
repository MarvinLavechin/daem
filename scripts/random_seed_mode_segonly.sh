#!/bin/bash

NUMBER_OF_JOBS=$1

for (( c=1; c<=$NUMBER_OF_JOBS; c++ ))
do
    sbatch -p gpucpuM train_apply_segmentation.sh
    sleep 1
done
