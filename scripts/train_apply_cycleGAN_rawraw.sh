#!/bin/bash
#SBATCH --gres=gpu:1
#SBATCH --mem 3500
#SBATCH -c 2
#SBATCH -t 119
#SBATCH -o out_batch
#SBATCH -e err_batch

#Default settings

##Can't set these settings
INPUT_DIR=datasets/cortex/stack1/raw/lower_resolution
INPUT_DIR_B=datasets/vnc/stack1/raw/lower_resolution

##Can set these settings
GENERATOR=unet

N_DENSE_LAYERS=5
N_DENSE_BLOCKS=5

U_DEPTH=8

N_RES_BLOCKS=9

N_HIGHWAY_UNITS=9

NGF=32

MAX_EPOCHS=2000
X_LOSS=hinge
Y_LOSS=hinge

RANDOM_SEED_MODE=false


while true ; do
    case "$1" in
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
        --x_loss)
        		shift ; X_LOSS=$1 ; shift ;;
        --y_loss)
                shift ; Y_LOSS=$1 ; shift ;;
        --ngf)
        		shift ; NGF=$1 ; shift ;;
        #Script mode
        --random_seed_mode)
                shift ; RANDOM_SEED_MODE=true ;;
        *) break;;
    esac
done

PARAM_GENERATOR=("--generator" "$GENERATOR")
if [ "$GENERATOR" = "unet" ]; then
    NGF=64
    PARAM_GENERATOR+=("--u_depth" "$U_DEPTH")
elif [ "$GENERATOR" = densenet ]; then
    PARAM_GENERATOR+=("--n_dense_layers" "$N_DENSE_LAYERS" "--n_dense_blocks" "$N_DENSE_BLOCKS")
elif [ "$GENERATOR" = highwaynet ]; then
    PARAM_GENERATOR+=("--n_highway_units" "$N_HIGHWAY_UNITS")
elif [ "$GENERATOR" = resnet ]; then
    PARAM_GENERATOR+=("--n_res_blocks" "$N_RES_BLOCKS")
fi
PARAM_GENERATOR+=("--ngf" "$NGF")

PARAM=("--max_epochs" "$MAX_EPOCHS" "--X_loss" "$X_LOSS" "--Y_loss" "$Y_LOSS")
PARAM=("${PARAM_GENERATOR[@]}" "${PARAM[@]}")

SUFFIX_NAME=$(echo ${PARAM[@]} | sed -e 's/ /_/g' | sed -e 's/--//g')
if [ "$RANDOM_SEED_MODE" = "true" ]; then
    DATE=`date '+%Y_%m_%d_%H_%M_%S'`
    SUFFIX_NAME="$SUFFIX_NAME"_"$DATE" #can't be setted
fi

OUTPUT_DIR=temp/Example_Transfer_RawRaw/train/train"$SUFFIX_NAME"

cd ..
source activate daem

### Train the CycleGAN model on the input_dir/train (training set)
TRAIN_COMMAND="python imagetranslation/translate.py --mode train \
--input_dir $INPUT_DIR/train \
--input_dir_B $INPUT_DIR_B \
--output_dir $OUTPUT_DIR \
--which_direction AtoB \
--discriminator unpaired \
--model CycleGAN \
--fliplr --flipud --transpose \
--display_freq 50 \
${PARAM[@]}"


if [ ! -d "$OUTPUT_DIR" ] || [ "$RANDOM_SEED_MODE" = "true" ]; then
    echo "Train CycleGAN :\n"
    eval $TRAIN_COMMAND
fi

## Apply the translation to the input_dir/val (validation set)
## Be sure that the 49.png image belongs to the validation set
OUTPUT_DIR_RESULTS=temp/Example_Transfer_RawRaw/test_da/test"$SUFFIX_NAME"
TEST_COMMAND="python imagetranslation/translate.py --mode test \
--checkpoint $OUTPUT_DIR \
--output_type translation_no_targets \
--model CycleGAN \
--input_dir $INPUT_DIR/val \
--output_dir $OUTPUT_DIR_RESULTS \
--image_height 512 \
--image_width 512"

if [ ! -d "$OUTPUT_DIR_RESULTS" ] || [ "$RANDOM_SEED_MODE" = "true" ]; then
    echo "Test CycleGAN\n"
    eval $TEST_COMMAND
fi

##Combine the only mouse translated image for which a label exists with its label
### Remove the repository examples/transfer1/paired_annotation/translated/ if it exists.
### Recreate it.
### Copy the translated image in examples/transfer1/paired_annotation/translated.
### Renamed the translated image in 49.png (in order to combine)
### Combine translated image and its label
COMBINE_COMMAND="rm -rf examples/transfer1/paired_annotation/translated/;
mkdir examples/transfer1/paired_annotation/translated/;
cp $OUTPUT_DIR_RESULTS/images/49-outputs.png examples/transfer1/paired_annotation/translated/;
mv examples/transfer1/paired_annotation/translated/49-outputs.png examples/transfer1/paired_annotation/translated/49.png;
python imagetranslation/tools/process.py  \
--operation combine \
--input_dir examples/transfer1/paired_annotation/translated/ \
--b_dir examples/transfer1/paired_annotation/labels/lower_resolution/ \
--output_dir datasets/cortex/paired_annotation/;
mv datasets/cortex/paired_annotation/49.png datasets/cortex/paired_annotation/combined/49_translated.png
"

eval $COMBINE_COMMAND

## Train a segmentation algorithm on the droso stack
OUTPUT_SEGMENTATION_TRAIN=temp/Example_2D_3Labels/train_lower_resolution

SEGMENTATION_TRAIN_COMMAND="python imagetranslation/translate.py   --mode train \
  --input_dir datasets/vnc/combined/train \
  --output_dir $OUTPUT_SEGMENTATION_TRAIN \
  --which_direction AtoB  --Y_loss square \
  --model pix2pix   --generator resnet \
  --fliplr   --flipud  --transpose \
  --max_epochs 2000  --display_freq 50"

if [ ! -d "$OUTPUT_SEGMENTATION_TRAIN" ]; then #even in random seed mode, we don't one to retrain the segmentation algorithm
    echo "Train Segmentation"
    eval $SEGMENTATION_TRAIN_COMMAND
fi

## Apply it on 49.png and 49_translated.png
OUTPUT_SEGMENTATION_TRANSLATED=temp/Example_Transfer_RawRaw/test_da_seg/test"$SUFFIX_NAME"
APPLY_SEGMENTATION_ON_TRANSLATED="python imagetranslation/translate.py   --mode test \
  --checkpoint $OUTPUT_SEGMENTATION_TRAIN \
  --input_dir datasets/cortex/paired_annotation/combined \
  --output_dir $OUTPUT_SEGMENTATION_TRANSLATED \
  --image_height 512  --image_width 512 --model pix2pix"

if [ ! -d "$OUTPUT_SEGMENTATION_TRANSLATED" ] || [ "$RANDOM_SEED_MODE" = "true" ]; then
    echo "Test Segmentation"
    eval $APPLY_SEGMENTATION_ON_TRANSLATED
fi

##Generate an html to output : ["input", "translated", "translated_segmented", "label"]
### A summary of hyper-parameters
### And obtained scores
NAME_TEST=test"$SUFFIX_NAME"
NAME_TRAIN=train"$SUFFIX_NAME"
HTML_FILE=temp/Example_Transfer_RawRaw/summary"$SUFFIX_NAME".html #can't be setted
PATH_INPUT="test_da/$NAME_TEST/images/49-inputs.png"
PATH_TRANSLATED="test_da/$NAME_TEST/images/49-outputs.png"
PATH_SEGMENTED="test_da_seg/$NAME_TEST/images/49_translated-outputs.png"
PATH_LABEL="test_da_seg/$NAME_TEST/images/49_translated-targets.png"

echo "<html><body><div><table><tr><th>name</th><th>input</th><th>translated</th><th>translated segmented</th><th>label</th></tr>" > $HTML_FILE
echo "<tr><td>49</td>" >> $HTML_FILE
echo "<td><img src='$PATH_INPUT'></td>" >> $HTML_FILE
echo "<td><img src='$PATH_TRANSLATED'></td>" >> $HTML_FILE
echo "<td><img src='$PATH_SEGMENTED'></td>" >> $HTML_FILE
echo "<td><img src='$PATH_LABEL'></td>" >> $HTML_FILE
echo "</tr> </table></div>" >> $HTML_FILE

## Seed value
VALUE_SEED_CYCLE_GAN_TRAIN=$(grep -oP '"seed":.*?[^\\],' temp/Example_Transfer_RawRaw/train/$NAME_TRAIN/options.json | cut -d" " -f2 | sed 's/.$//')
VALUE_SEED_CYCLE_GAN_TEST=$(grep -oP '"seed":.*?[^\\],' temp/Example_Transfer_RawRaw/test_da/$NAME_TEST/options.json | cut -d" " -f2 | sed 's/.$//')
echo "<p>Value of the seed during the training phase (CycleGAN) : $VALUE_SEED_CYCLE_GAN_TRAIN</p>" >> $HTML_FILE
echo "<p>Value of the seed during the testing phase (CycleGAN) : $VALUE_SEED_CYCLE_GAN_TEST</p>" >> $HTML_FILE

## Hyper-parameters value
echo "<p>Here some hyper-parameters ...</p>" >> $HTML_FILE

for (( i=0; i<${#PARAM[@]} ; i+=2 )) ; do
    echo "<p>${PARAM[i]/--/}" : "${PARAM[i+1]}</p>"  >> $HTML_FILE
done

## Evaluation results
echo "<p>Evaluation results ...</p>" >> $HTML_FILE

## Run evaluations for each channel (red = synapse, green = mitochondria, blue = membrane)
EVAL0="python tools/evaluate.py --predicted \"temp/Example_Transfer_RawRaw/test_da_seg/$NAME_TEST/images/49_translated-outputs.png\" \
--true \"temp/Example_Transfer_RawRaw/test_da_seg/$NAME_TEST/images/49_translated-targets.png\" \
--output temp/Example_Transfer_RawRaw/test_da_seg/evaluation-synapses.csv  --channel 0"
EVAL1="python tools/evaluate.py --predicted \"temp/Example_Transfer_RawRaw/test_da_seg/$NAME_TEST/images/49_translated-outputs.png\" \
--true \"temp/Example_Transfer_RawRaw/test_da_seg/$NAME_TEST/images/49_translated-targets.png\" \
--output temp/Example_Transfer_RawRaw/test_da_seg/evaluation-mitochondria.csv  --channel 1"
EVAL2="python tools/evaluate.py --predicted \"temp/Example_Transfer_RawRaw/test_da_seg/$NAME_TEST/images/49_translated-outputs.png\" \
--true \"temp/Example_Transfer_RawRaw/test_da_seg/$NAME_TEST/images/49_translated-targets.png\" \
--output temp/Example_Transfer_RawRaw/test_da_seg/evaluation-membranes.csv  --channel 2 --segment_by 1"

SCORE_SYNAPSE=$(eval $EVAL0)
SCORE_SYNAPSE=${SCORE_SYNAPSE/*".png"/} #we clean variables from superfluous text
SCORE_SYNAPSE=${SCORE_SYNAPSE/"Saved to"*/}

SCORE_MITOCHONDRIA=$(eval $EVAL1)
SCORE_MITOCHONDRIA=${SCORE_MITOCHONDRIA/*".png"/}
SCORE_MITOCHONDRIA=${SCORE_MITOCHONDRIA/"Saved to"*/}
SCORE_MEMBRANE=$(eval $EVAL2)
SCORE_MEMBRANE=${SCORE_MEMBRANE/*".png"/}
SCORE_MEMBRANE=${SCORE_MEMBRANE/"Saved to"*/}

echo "<br/>" >> $HTML_FILE
echo "<p>Results on membrane :</p>" >> $HTML_FILE
echo "<p>$SCORE_MEMBRANE</p>" >> $HTML_FILE
echo "<br/>" >> $HTML_FILE
echo "<p>Results on mitochondria :</p>" >> $HTML_FILE
echo "<p>$SCORE_MITOCHONDRIA</p>" >> $HTML_FILE
echo "<br/>" >> $HTML_FILE
echo "<p>Results on synapse :</p>" >> $HTML_FILE
echo "<p>$SCORE_SYNAPSE</p>" >> $HTML_FILE
echo "<br/>" >> $HTML_FILE

EVAL_TRANSLATION="python tools/compare.py --inputA temp/Example_Transfer_RawRaw/test_da_seg/$NAME_TEST/images/49-inputs.png \
--inputB temp/Example_Transfer_RawRaw/test_da_seg/$NAME_TEST/images/49_translated-inputs.png"

PSNR=$(eval $EVAL_TRANSLATION)
PSNR=${PSNR/PSNR = /}
echo "<p>PSNR input / translated :</p>" >> $HTML_FILE
echo "<p>$PSNR</p>" >> $HTML_FILE
echo "</body></html>" >> $HTML_FILE

#Finally, we rename the html_file to index it according to the average of the scored obtained on membrane and mitochondrias
error_membrane="$(echo $SCORE_MEMBRANE | sed 's/.*adapted_RAND_error = //')"
error_mitochondria="$(echo $SCORE_MITOCHONDRIA | sed 's/.*adapted_RAND_error = //')"
average=$(echo "scale = 3;($error_membrane+$error_mitochondria)/2.0" | bc -l | sed -r 's/^(-?)\./\10./')
NEW_HTML_FILE=temp/Example_Transfer_RawRaw/"$average"summary"$SUFFIX_NAME".html
mv $HTML_FILE $NEW_HTML_FILE

#We save it as a pdf file.
wkhtmltopdf -O landscape $NEW_HTML_FILE ~/Documents/"$average"summary"$SUFFIX_NAME".pdf


