#!/bin/bash

# ------------------------------------------------------------------------------
# Install miniconda
# ------------------------------------------------------------------------------
# credits: @pangyuteng
# refer to: https://gist.github.com/pangyuteng/f5b00fe63ac31a27be00c56996197597
# Use the above args during building https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact
# Choices
# PLATFORM: Linux, MacOSX, or Windows
# OS_TYPE : x86_64, arm64, ppc64le, s390x, or x86, armv7l
CONDA_VER=latest
PLATFORM=Linux
OS_TYPE=x86_64
INSTALLDIR=$HOME/miniconda
# Install miniconda to /miniconda
curl -LO "http://repo.continuum.io/miniconda/Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh" \
    && bash Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh -p $INSTALLDIR -b \
    && rm Miniconda3-${CONDA_VER}-Linux-${OS_TYPE}.sh

# add the following to .bashrc
export PATH=$INSTALLDIR/bin:${PATH}

# init
conda init bash
