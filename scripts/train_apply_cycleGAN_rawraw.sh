#!/bin/bash
#SBATCH --gres=gpu:1
#SBATCH --mem 4000
#SBATCH -c 2
#SBATCH -t 800
#SBATCH -o out_batch
#SBATCH -e err_batch

#Default settings

##Can't set these settings
INPUT_DIR=datasets/cortex/stack1/raw/lower_resolution
INPUT_DIR_B=datasets/vnc/stack1/raw/lower_resolution
DISPLAY_FREQ=50

##Can set these settings
N_DENSE_LAYERS=5
N_DENSE_BLOCKS=5
MAX_EPOCHS=2000
X_LOSS=hinge
Y_LOSS=hinge

while true ; do
    case "$1" in
        --n_dense_layers) 
        		shift ; N_DENSE_LAYERS=$1 ; shift ;;
        --n_dense_blocks) 
        		shift ; N_DENSE_BLOCKS=$1 ; shift ;;
        --max_epochs) 
        		shift ; MAX_EPOCHS=$1 ; shift ;;
        --x_loss)
        		shift ; X_LOSS=$1 ; shift ;;
        --y_loss)
                shift ; qY_LOSS=$1 ; shift ;;
        "") break;;
    esac
done

OUTPUT_DIR=temp/Example_Transfer_RawRaw/train/train_me"$MAX_EPOCHS"_ndb"$N_DENSE_BLOCKS"_ndl"$N_DENSE_LAYERS"_xloss"$X_LOSS"_yloss"$Y_LOSS" #can't be setted

cd ..
source activate daem

## Train the CycleGAN model on the input_dir/train (training set)
TRAIN_COMMAND="python imagetranslation/translate.py --mode train \
--input_dir $INPUT_DIR/train \
--input_dir_B $INPUT_DIR_B \
--output_dir $OUTPUT_DIR \
--which_direction AtoB \
--discriminator unpaired \
--X_loss $X_LOSS \
--Y_loss $Y_LOSS \
--model CycleGAN --generator resnet \
--fliplr --flipud --transpose \
--max_epochs $MAX_EPOCHS \
--n_dense_layers $N_DENSE_LAYERS \
--n_dense_blocks $N_DENSE_BLOCKS \
--display_freq $DISPLAY_FREQ"

eval $TRAIN_COMMAND

## Apply the translation to the input_dir/val (validation set)
OUTPUT_DIR_RESULTS=temp/Example_Transfer_RawRaw/test/test_me"$MAX_EPOCHS"_ndb"$N_DENSE_BLOCKS"_ndl"$N_DENSE_LAYERS"_xloss"$X_LOSS"_yloss"$Y_LOSS" #can't be setted
TEST_COMMAND="python imagetranslation/translate.py --mode test \
--checkpoint $OUTPUT_DIR \
--no_targets \
--model CycleGAN \
--input_dir $INPUT_DIR/val \
--output_dir $OUTPUT_DIR_RESULTS \
--image_height 512 \
--image_width 512"

eval $TEST_COMMAND
