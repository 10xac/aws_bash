#!/bin/bash

# This script setup a conda environment that contains dependencies of
# for satellite image and LIDAR data based challenge

#Reference - mainly adopted from
#https://github.com/aws-samples/aws-open-data-satellite-lidar-tutorial

# Exit when error occurs
set -e

folder=${PYTHON_DIR:-/opt/miniconda}

# Create conda environment if name passed
if [ $# -gt 0 ]; then
    export ENV_NAME=$1
    echo "creating conda environment name=$ENV_NAME .."    
    conda create -n $ENV_NAME -y --channel conda-forge
    # Activate the environment in Bash shell
    conda activate $ENV_NAME
fi

# Install dependencies
#conda install --file conda-requirements.txt -y --channel conda-forge
pip install -r requirements.txt
