#!/usr/bin/env bash

# Get the Drosophila VNC dataset
git clone https://github.com/tbullmann/groundtruth-drosophila-vnc datasets/vnc

# Get the Mouse Cortex dataset
git clone https://github.com/tbullmann/groundtruth-drosophila-vnc datasets/cortex
cd datasets/cortex
bash download-and-convert.sh
cd ../..



