#!/bin/zsh

# Aim: create conda env
BASE=$(dirname $(dirname $(realpath $0)))  # path to diffdock-pp
conda env create -f $BASE/environment.yml  # create env called `diffdock`