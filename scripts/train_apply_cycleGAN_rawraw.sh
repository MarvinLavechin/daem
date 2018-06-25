#!/bin/bash
#SBATCH --gres=gpu:1
#SBATCH --mem 17000
#SBATCH -c 2
#SBATCH -t 600
#SBATCH -o out_batch
#SBATCH -e err_batch

##Can set these settings
RANDOM_SEED_MODE=false
RANDOM_INIT_MODE=false

while true ; do
    case "$1" in
        --seed)
                shift ; SEED=$1 ; shift ;;
        --generator)                                # unet, resnet, highwaynet or densenet
        		shift ; GENERATOR=$1 ; shift ;;
        #Dense net parameters
        --n_dense_layers)
        		shift ; N_DENSE_LAYERS=$1 ; shift ;;
        --n_dense_blocks)
        		shift ; N_DENSE_BLOCKS=$1 ; shift ;;

        #U net parameter
        --u_depth)
        		shift ; U_DEPTH=$1 ; shift ;;

        #Resnet parameter
        --n_res_blocks)
        		shift ; N_RES_BLOCKS=$1 ; shift ;;

        #Highway net parameter
        --n_highway_units)
        		shift ; N_HIGHWAY_UNITS=$1 ; shift ;;

        #Other parameters of discriminators and generators
        --max_epochs)
        		shift ; MAX_EPOCHS=$1 ; shift ;;
        --max_steps)
        		shift ; MAX_STEPS=$1 ; shift ;;
        --x_loss)
        		shift ; X_LOSS=$1 ; shift ;;
        --y_loss)
                shift ; Y_LOSS=$1 ; shift ;;
        --ngf)
        		shift ; NGF=$1 ; shift ;;
        #Segmentation loss while training cycleGAN parameters
        --checkpoint_segmentation)
                shift ; CHECKPOINT_SEGMENTATION=$1 ; shift ;;
        --weight_segmentation)
                shift ; WEIGHT_SEGMENTATION=$1 ; shift ;;
        #Script mode
        --random_seed_mode)
                shift ; RANDOM_SEED_MODE=true ;;
        --random_init_mode)
                shift ; RANDOM_INIT_MODE=true ;;
        #Transformations parameters
        --no_flipud)
            shift ; NO_FLIPUD=true ;;
        --no_fliplr)
            shift ; NO_FLIPLR=true ;;
        --no_transpose)
            shift ; NO_TRANSPOSE=true ;;
        --flipud)
            shift ; FLIPUD=true ;;
        --fliplr)
            shift ; FLIPLR=true ;;
        --transpose)
            shift ; TRANSPOSE=true ;;
        *) break;;
    esac
done

PARAM=()
if [ "$GENERATOR" != "" ]; then PARAM+=("--generator" "$GENERATOR") ;fi
if [ "$N_DENSE_LAYERS" != "" ]; then PARAM+=("--n_dense_layers" "$N_DENSE_LAYERS") ;fi
if [ "$N_DENSE_BLOCKS" != "" ]; then PARAM+=("--n_dense_blocks" "$N_DENSE_BLOCKS") ;fi
if [ "$U_DEPTH" != "" ]; then PARAM+=("--u_depth" "$U_DEPTH") ;fi
if [ "$N_RES_BLOCKS" != "" ]; then PARAM+=("--n_res_blocks" "$N_RES_BLOCKS") ;fi
if [ "$N_HIGHWAY_UNITS" != "" ]; then PARAM+=("--n_highway_units" "$N_HIGHWAY_UNITS") ;fi
if [ "$MAX_EPOCHS" != "" ]; then PARAM+=("--max_epochs" "$MAX_EPOCHS") ;fi
if [ "$MAX_STEPS" != "" ]; then PARAM+=("--max_steps" "$MAX_STEPS") ;fi
if [ "$X_LOSS" != "" ]; then PARAM+=("--X_loss" "$X_LOSS") ;fi
if [ "$Y_LOSS" != "" ]; then PARAM+=("--Y_loss" "$Y_LOSS") ;fi
if [ "$NGF" != "" ]; then PARAM+=("--ngf" "$NGF") ;fi
if [ "$CHECKPOINT_SEGMENTATION" != "" ]; then PARAM+=("--checkpoint_segmentation" "$CHECKPOINT_SEGMENTATION") ;fi
if [ "$WEIGHT_SEGMENTATION" != "" ]; then PARAM+=("--weight_segmentation" "$WEIGHT_SEGMENTATION") ;fi
if [ "$SEED" != "" ]; then PARAM+=("--seed" "$SEED") ;fi
if [ "$FLIPUD" != "" ]; then PARAM+=("--flipud") ;fi
if [ "$FLIPLR" != "" ]; then PARAM+=("--fliplr") ;fi
if [ "$TRANSPOSE" != "" ]; then PARAM+=("--transpose") ;fi
if [ "$NO_FLIPUD" != "" ]; then PARAM+=("--no_flipud") ;fi
if [ "$NO_FLIPLR" != "" ]; then PARAM+=("--no_fliplr") ;fi
if [ "$NO_TRANSPOSE" != "" ]; then PARAM+=("--no_transpose") ;fi

if [ "$RANDOM_INIT_MODE" = "true" ]; then
    RANDOM_SEED_MODE=true
    PARAM+=("--random_init")
fi

SUFFIX_NAME=$(echo ${PARAM[@]} | sed -e 's/--checkpoint_segmentation.*--w/--w/g' | sed -e 's/ /_/g' | sed -e 's/--//g')

echo "Suffix name chosen for the file"
echo $SUFFIX_NAME

if [ "$RANDOM_SEED_MODE" = "true" ]; then
    DATE=`date '+%Y_%m_%d_%H_%M_%S'`
    SUFFIX_NAME="$SUFFIX_NAME"_"$DATE" #can't be setted
fi

if [ "$CHECKPOINT_SEGMENTATION" != "" ] && [ "$WEIGHT_SEGMENTATION" != "" ]; then
    # Semi-supervised case
    INPUT_DIR=datasets/cropped_cortex/combined/train
    INPUT_DIR_B=datasets/cropped_vnc/combined/train
    OUTPUT_DIR=temp/Example_Domain_Adaptation_Semi_Supervised
else
    # Unsupervised case
    # No need to have a training and validation set in this case.
    # Because impossible to evaluate "the accuracy" of the translation.
    INPUT_DIR=datasets/cropped_cortex/stack1/raw/train
    INPUT_DIR_B=datasets/cropped_vnc/stack1/raw
    OUTPUT_DIR=temp/Example_Domain_Adaptation_Unsupervised
fi

OUTPUT_TRAIN_CYCLE_GAN="$OUTPUT_DIR/train_domain_adaptation/train$SUFFIX_NAME"

cd ..
source activate daem

### Train the CycleGAN model on the input_dir/train (training set)
TRAIN_COMMAND="python imagetranslation/translate.py --mode train \
--input_dir $INPUT_DIR \
--input_dir_B $INPUT_DIR_B \
--output_dir $OUTPUT_TRAIN_CYCLE_GAN \
--which_direction AtoB \
--discriminator unpaired \
--model CycleGAN \
--fliplr --flipud --transpose \
--display_freq 500 \
${PARAM[@]}"

if [ ! -d "$OUTPUT_TRAIN_CYCLE_GAN" ] || [ "$RANDOM_SEED_MODE" = "true" ]; then
    echo "Train CycleGAN :\n"
    eval $TRAIN_COMMAND
fi

## Apply the translation to the input_dir/val (validation set)
## In the case of non-cropped images, be sure that the 49.png image belongs
## to the validation set.

OUTPUT_DIR_RESULTS_CYCLE_GAN="$OUTPUT_DIR/test_domain_adaptation/test$SUFFIX_NAME"
TEST_COMMAND="python imagetranslation/translate.py --mode test \
--checkpoint $OUTPUT_TRAIN_CYCLE_GAN \
--model CycleGAN \
--input_dir datasets/cropped_cortex/combined/val \
--output_dir $OUTPUT_DIR_RESULTS_CYCLE_GAN \
--seed 0 \
--image_height 512 \
--image_width 512"

if [ ! -d "$OUTPUT_DIR_RESULTS_CYCLE_GAN" ] || [ "$RANDOM_SEED_MODE" = "true" ]; then
    echo "Test CycleGAN\n"
    eval $TEST_COMMAND
fi

### Combine the only mouse translated image for which a label exists with its label
### Remove the repository examples/transfer1/paired_annotation/translated/ if it exists.
### Recreate it.
### Copy the translated image in examples/transfer1/paired_annotation/translated.
### Renamed the translated image in 49.png (in order to combine)
### Combine translated image and its label
TRANSLATED_LABEL_DIR="$OUTPUT_DIR/translated_images/translated$SUFFIX_NAME"
COMBINE_COMMAND="
mkdir -p $OUTPUT_DIR/translated_images/translated$SUFFIX_NAME;
cp $OUTPUT_DIR_RESULTS_CYCLE_GAN/images/*-outputs.png $TRANSLATED_LABEL_DIR;
rename 's/-outputs//' $TRANSLATED_LABEL_DIR/*-outputs.png;
python imagetranslation/tools/process.py  \
--operation combine \
--input_dir $TRANSLATED_LABEL_DIR \
--b_dir datasets/cropped_cortex/stack1/labels/ \
--output_dir $TRANSLATED_LABEL_DIR/paired_annotation/;
rename 's/.png/_translated.png/' $TRANSLATED_LABEL_DIR/paired_annotation/*.png;
"

eval $COMBINE_COMMAND

## Train a segmentation algorithm on the droso stack
OUTPUT_SEGMENTATION_TRAIN="temp/Example_2D_3Labels/train_on_cropped"

## Apply it on 49_translated.png
OUTPUT_SEGMENTATION_TRANSLATED=$OUTPUT_DIR/test_domain_adaptation_segmentation/test"$SUFFIX_NAME"
APPLY_SEGMENTATION_ON_TRANSLATED="python imagetranslation/translate.py   --mode test \
  --checkpoint $OUTPUT_SEGMENTATION_TRAIN \
  --input_dir $TRANSLATED_LABEL_DIR/paired_annotation/ \
  --output_dir $OUTPUT_SEGMENTATION_TRANSLATED \
  --image_height 512  --image_width 512 --model pix2pix --seed 0"

if [ ! -d "$OUTPUT_SEGMENTATION_TRANSLATED" ] || [ "$RANDOM_SEED_MODE" = "true" ]; then
    echo "Test Segmentation"
    eval $APPLY_SEGMENTATION_ON_TRANSLATED
fi

##Generate an html to output : ["input", "translated", "translated_segmented", "label"]
### A summary of hyper-parameters
### And obtained scores
NAME_TEST=test"$SUFFIX_NAME"
NAME_TRAIN=train"$SUFFIX_NAME"
HTML_FILE=$OUTPUT_DIR/summary"$SUFFIX_NAME".html #can't be setted

echo "<html><body><div><table><tr><th>name</th><th>input</th><th>translated</th><th>translated segmented</th><th>label</th></tr>" > $HTML_FILE
for image in $OUTPUT_DIR/test_domain_adaptation/$NAME_TEST/images/*-inputs.png; do
    NUMBER_IMAGE=$(echo $image | sed 's/-inputs.png//' | sed 's/.*\///')
    PATH_INPUT=test_domain_adaptation/$NAME_TEST/images/$NUMBER_IMAGE-inputs.png
    PATH_TRANSLATED=test_domain_adaptation/$NAME_TEST/images/$NUMBER_IMAGE-outputs.png
    PATH_SEGMENTED=test_domain_adaptation_segmentation/${NAME_TEST}/images/${NUMBER_IMAGE}_translated-outputs.png
    PATH_LABEL=test_domain_adaptation_segmentation/${NAME_TEST}/images/${NUMBER_IMAGE}_translated-targets.png

    echo "<tr><td>$NUMBER_IMAGE</td>" >> $HTML_FILE
    echo "<td><img src='$PATH_INPUT'></td>" >> $HTML_FILE
    echo "<td><img src='$PATH_TRANSLATED'></td>" >> $HTML_FILE
    echo "<td><img src='$PATH_SEGMENTED'></td>" >> $HTML_FILE
    echo "<td><img src='$PATH_LABEL'></td></tr>" >> $HTML_FILE
done
echo "</table></div>" >> $HTML_FILE


## Seed value
VALUE_SEED_CYCLE_GAN_TRAIN=$(grep -oP '"seed":.*?[^\\],' $OUTPUT_DIR/train_domain_adaptation/$NAME_TRAIN/options.json | cut -d" " -f2 | sed 's/.$//')
VALUE_SEED_CYCLE_GAN_TEST=$(grep -oP '"seed":.*?[^\\],' $OUTPUT_DIR/test_domain_adaptation/$NAME_TEST/options.json | cut -d" " -f2 | sed 's/.$//')
echo "<p>Value of the seed during the training phase (CycleGAN) : $VALUE_SEED_CYCLE_GAN_TRAIN</p>" >> $HTML_FILE

## Hyper-parameters value
PARAMETERS_FILE="$OUTPUT_DIR_RESULTS_CYCLE_GAN/options.json"
LIST_HYPER_PARAMETERS="X_loss Y_loss beta1 classic_weight gan_weight gen_loss generator loss
                       lr max_epochs max_steps n_dense_blocks n_dense_layers n_highway_units
                       n_res_blocks ndf ngf u_depth"

function contains {
    local list="$1"
    local item="$2"
    if [[ $list =~ (^|[[:space:]])"$item"($|[[:space:]]) ]] ; then
        # yes, list include item
        result=1
    else
        result=0
    fi
    return $result
}

echo "<table BORDER="1">" >> $HTML_FILE
echo "<caption>Here the hyper-parameters ...</caption>" >> $HTML_FILE
i=1
while read p; do
    PARAMETER=$(echo $p | sed 's/\"\:.*$//' | sed 's/\"//' )
    VALUE=$(echo $p | sed 's/.*\://' | sed 's/\"//g' | sed 's/\,//g' )

    contains "${LIST_HYPER_PARAMETERS[@]}" $PARAMETER
    IS_HYPER_PARAMETER=$?

    if [ $IS_HYPER_PARAMETER = 1 ]; then

        MODULUS=$(( $i  % 6 ))
        if [ $MODULUS = 1 ]; then
            echo "<tr>" >> $HTML_FILE
        fi

        echo "<td>$PARAMETER : $VALUE</td>" >> $HTML_FILE

        if [ $MODULUS = 0 ]; then
            echo "</tr>" >> $HTML_FILE
        fi

        i=$(($i+1))
    fi
done <$PARAMETERS_FILE

echo "</table>" >> $HTML_FILE

## Evaluation results
echo "<p>Evaluation results ...</p>" >> $HTML_FILE

## Run evaluations for each channel (red = synapse, green = mitochondria, blue = membrane)
EVAL_PREDICTED_DIR=$OUTPUT_DIR/test_domain_adaptation_segmentation/$NAME_TEST/images/*_translated-outputs.png
EVAL_TRUE_DIR=$OUTPUT_DIR/test_domain_adaptation_segmentation/$NAME_TEST/images/*_translated-targets.png
EVAL_OUTPUT_DIR=$OUTPUT_DIR/test_domain_adaptation_segmentation
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

for image in $OUTPUT_DIR/test_domain_adaptation/$NAME_TEST/images/*-inputs.png; do
    NUMBER_IMAGE=$(echo $image | sed 's/-inputs.png//' | sed 's/.*\///')
    EVAL_TRANSLATION="python tools/compare.py --inputA $OUTPUT_DIR/test_domain_adaptation/$NAME_TEST/images/$NUMBER_IMAGE-inputs.png \
    --inputB $OUTPUT_DIR/test_domain_adaptation_segmentation/$NAME_TEST/images/'$NUMBER_IMAGE'_translated-inputs.png"
    PSNR=$(eval $EVAL_TRANSLATION)
    PSNR=${PSNR/PSNR = /}
    echo "<p>PSNR input / translated on image $NUMBER_IMAGE : " >> $HTML_FILE
    echo "$PSNR </p>" >> $HTML_FILE
done
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

#We remove temporary files to avoid to run out of memory
#rm -rf $OUTPUT_DIR
#rm -rf $OUTPUT_DIR_RESULTS
#rm -rf $OUTPUT_SEGMENTATION_TRANSLATED#!/usr/bin/env bash
