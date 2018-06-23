#!/usr/bin/env bash
#SBATCH --gres=gpu:1
#SBATCH --mem 8000
#SBATCH -c 2
#SBATCH -t 600
#SBATCH -o out_batch
#SBATCH -e err_batch

MAX_EPOCHS=1000
DATE=`date '+%Y_%m_%d_%H_%M_%S'`

cd ..
source activate daem

OUTPUT_DIR="temp/Example_trained_on_vnc"
INPUT_DIR="datasets/cropped_vnc/combined"

##Train the segmentation algorithm on drosophila vnc
OUTPUT_DIR_TRAIN="$OUTPUT_DIR/train_segmentation/train$DATE"
TRAIN_COMMAND="python imagetranslation/translate.py  --mode train \
  --input_dir $INPUT_DIR/train \
  --output_dir $OUTPUT_DIR_TRAIN \
  --which_direction AtoB  --Y_loss square \
  --model pix2pix   --generator unet \
  --fliplr   --flipud  --transpose \
  --max_epochs $MAX_EPOCHS  --display_freq 400"

eval $TRAIN_COMMAND

##Test the segmentation algorithm on cortex
TEST_FOLDER="datasets/cropped_cortex/combined"
OUTPUT_DIR_TEST="$OUTPUT_DIR/test_segmentation/test$DATE"
TEST_COMMAND="python imagetranslation/translate.py   --mode test \
  --checkpoint $OUTPUT_DIR_TRAIN \
  --input_dir $TEST_FOLDER/val \
  --output_dir $OUTPUT_DIR_TEST \
  --image_height 512  --image_width 512 \
  --model pix2pix"

eval $TEST_COMMAND

###Evaluate the segmentation algorithm on membranes
#PREDICTED_FOLDER="$OUTPUT_DIR_TEST/images/*outputs.png"
#LABEL_FOLDER="$OUTPUT_DIR_TEST/images/*targets.png"
#OUTPUT_EVALUATION="temp/Example_2D_3Labels/test_segmentation/test$DATE/evaluation-membranes.csv"
#EVALUATE_MEMBRANE="python tools/evaluate.py \
#  --predicted \"$PREDICTED_FOLDER\" \
#  --true \"$LABEL_FOLDER\" \
#  --output \"$OUTPUT_EVALUATION\" --channel 2  --segment_by 1"
#
#SCORE_MEMBRANE=$(eval $EVALUATE_MEMBRANE)
#SCORE_MEMBRANE=${SCORE_MEMBRANE/*".png"/}
#SCORE_MEMBRANE=${SCORE_MEMBRANE/"Saved to"*/}
#
#error_membrane="$(echo $SCORE_MEMBRANE | sed 's/.*adapted_RAND_error = //')"
#echo $error_membrane > temp/Example_2D_3Labels/test_segmentation/test${DATE}_$error_membrane

## Evaluation results
NAME_TEST=test$DATE
HTML_FILE=$OUTPUT_DIR/summary$DATE.html
SUFFIX_NAME=$DATE

echo "<p>Evaluation results ...</p>" >> $HTML_FILE

## Run evaluations for each channel (red = synapse, green = mitochondria, blue = membrane)
EVAL_PREDICTED_DIR=$OUTPUT_DIR/test_segmentation/$NAME_TEST/images/*-outputs.png
EVAL_TRUE_DIR=$OUTPUT_DIR/test_segmentation/$NAME_TEST/images/*-targets.png
EVAL_OUTPUT_DIR=$OUTPUT_DIR/test_segmentation
EVAL0="python tools/evaluate.py --predicted \"$EVAL_PREDICTED_DIR\" \
--true \"$EVAL_TRUE_DIR\" \
--output $EVAL_OUTPUT_DIR/evaluation-synapses$SUFFIX_NAME.csv  --channel 0"
EVAL1="python tools/evaluate.py --predicted \"$EVAL_PREDICTED_DIR\" \
--true \"$EVAL_TRUE_DIR\" \
--output $EVAL_OUTPUT_DIR/evaluation-mitochondria$SUFFIX_NAME.csv  --channel 1"
EVAL2="python tools/evaluate.py --predicted \"$EVAL_PREDICTED_DIR\" \
--true \"$EVAL_TRUE_DIR\" \
--output $EVAL_OUTPUT_DIR/evaluation-membranes$SUFFIX_NAME.csv  --channel 2 --segment_by 1"

SCORE_SYNAPSE=$(eval $EVAL0)
SCORE_SYNAPSE=${SCORE_SYNAPSE/*".png"/} #we clean variables from superfluous text
SCORE_SYNAPSE=${SCORE_SYNAPSE/"Saved to"*/}

SCORE_MITOCHONDRIA=$(eval $EVAL1)
SCORE_MITOCHONDRIA=${SCORE_MITOCHONDRIA/*".png"/}
SCORE_MITOCHONDRIA=${SCORE_MITOCHONDRIA/"Saved to"*/}
SCORE_MEMBRANE=$(eval $EVAL2)
SCORE_MEMBRANE=${SCORE_MEMBRANE/*".png"/}
SCORE_MEMBRANE=${SCORE_MEMBRANE/"Saved to"*/}

echo "<p>Results on membrane : " >> $HTML_FILE
echo "$SCORE_MEMBRANE</p>" >> $HTML_FILE
echo "<p>Results on mitochondria : " >> $HTML_FILE
echo "$SCORE_MITOCHONDRIA</p>" >> $HTML_FILE
echo "<p>Results on synapse : " >> $HTML_FILE
echo "$SCORE_SYNAPSE</p>" >> $HTML_FILE
echo "</body></html>" >> $HTML_FILE

#Finally, we rename the html_file to index it according to the average score obtained on membrane and mitochondria
error_membrane="$(echo $SCORE_MEMBRANE | sed 's/.*adapted_RAND_error = //')"
error_mitochondria="$(echo $SCORE_MITOCHONDRIA | sed 's/.*adapted_RAND_error = //')"
average=$(echo "scale = 3;($error_membrane+$error_mitochondria)/2.0" | bc -l | sed -r 's/^(-?)\./\10./')
NEW_HTML_FILE=$OUTPUT_DIR/"$average"summary"$SUFFIX_NAME".html
mv $HTML_FILE $NEW_HTML_FILE

#We save the html file, and its pdf version if everything has been executed correctly.
if [ -f "$OUTPUT_DIR/test_domain_adaptation_segmentation/$NAME_TEST/images/*-inputs.png" ] && [ -f "$OUTPUT_DIR/test_domain_adaptation_segmentation/$NAME_TEST/images/*_translated-inputs.png" ] && [ $error_membrane != 0 ]; then
    wkhtmltopdf -O landscape $NEW_HTML_FILE ~/Documents/"$average"summary"$SUFFIX_NAME".pdf
    mkdir -p ~/Documents_html
    mv $NEW_HTML_FILE ~/Documents_html
fi