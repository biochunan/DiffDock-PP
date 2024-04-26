#!/bin/zsh

# Aim: run diffdock job

# activate conda env
conda init zsh > /dev/null 2>&1
source ~/.zshrc
conda activate diffdock

# run the thing
python run_one_abdb.py $@