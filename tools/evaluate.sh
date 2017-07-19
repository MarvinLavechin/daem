#!/usr/bin/env

# $1 = directory
# $2 = label

# example:
# bash tools/evaluate.sh temp/Example_2D_3Labels/test/images membranes

case $2 in
synapses)
    channel=0
    background=0
  ;;
mitochondria)
    channel=1
    background=0
  ;;
membranes)
    channel=2
    background=1
  ;;
esac

mkdir -p $1/evaluation

python tools/evaluate.py \
  --input "$1/images/*inputs.png" \
  --predicted "$1/images/*outputs.png" \
  --true "$1/images/*targets.png" \
  --output $1/evaluation/$2.csv  --channel $channel  --segment_by $background  --plot save


