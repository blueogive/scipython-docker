#!/bin/bash

mamba env create -f ~/miniforge3/examples/conda-env-minimal.yml
mamba activate minimal
Rscript -e "IRkernel::installspec()"
jupyter lab build
jupyter lab --no-browser --ip 0.0.0.0 --notebook-dir=~/work
