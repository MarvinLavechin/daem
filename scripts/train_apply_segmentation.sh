#!/usr/bin/env bash
#SBATCH --gres=gpu:1
#SBATCH --mem 8000
#SBATCH -c 2
#SBATCH -t 600
#SBATCH -o out_batch
#SBATCH -e err_batchs

MAX_EPOCHS=2000
DATE=`date '+%Y_%m_%d_%H_%M_%S'`

cd ..
source activate daem

INPUT_DIR="datasets/cropped_vnc/combined"

##Train the segmentation algorithm
OUTPUT_DIR_TRAIN="temp/Example_2D_3Labels/train_segmentation/train$DATE"
TRAIN_COMMAND="python imagetranslation/translate.py  --mode train \
  --input_dir $INPUT_DIR/train \
  --output_dir $OUTPUT_DIR_TRAIN \
  --which_direction AtoB  --Y_loss square \
  --model pix2pix   --generator resnet \
  --fliplr   --flipud  --transpose \
  --max_epochs $MAX_EPOCHS  --display_freq 400"

eval $TRAIN_COMMAND

##Test the segmentation algorithm
OUTPUT_DIR_TEST="temp/Example_2D_3Labels/test_segmentation/test$DATE"
TEST_COMMAND="python imagetranslation/translate.py   --mode test \
  --checkpoint $OUTPUT_DIR_TRAIN \
  --input_dir $INPUT_DIR/val \
  --output_dir $OUTPUT_DIR_TEST \
  --image_height 512  --image_width 512 \
  --model pix2pix"

eval $TEST_COMMAND

##Evaluate the segmentation algorithm on membranes
PREDICTED_FOLDER="$OUTPUT_DIR_TEST/images/*outputs.png"
LABEL_FOLDER="$OUTPUT_DIR_TEST/images/*targets.png"
OUTPUT_EVALUATION="temp/Example_2D_3Labels/test_segmentation/test$DATE/evaluation-membranes.csv"
EVALUATE_MEMBRANE="python tools/evaluate.py \
  --predicted \"$PREDICTED_FOLDER\" \
  --true \"$LABEL_FOLDER\" \
  --output \"$OUTPUT_EVALUATION\" --channel 2  --segment_by 1"

SCORE_MEMBRANE=$(eval $EVALUATE_MEMBRANE)
SCORE_MEMBRANE=${SCORE_MEMBRANE/*".png"/}
SCORE_MEMBRANE=${SCORE_MEMBRANE/"Saved to"*/}

error_membrane="$(echo $SCORE_MEMBRANE | sed 's/.*adapted_RAND_error = //')"
echo $error_membrane > temp/Example_2D_3Labels/test_segmentation/test${DATE}_$error_membrane