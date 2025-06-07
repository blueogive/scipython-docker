#!/bin/bash

Rscript -e "IRkernel::installspec()"
jupyter lab build --dev-build=False --minimize=False
jupyter lab --no-browser --ip 0.0.0.0 --notebook-dir=~/work
