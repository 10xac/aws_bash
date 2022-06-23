#!/bin/bash

# This script setup a conda environment that contains dependencies of
# for satellite image and LIDAR data based challenge

#Reference - mainly adopted from
#https://github.com/aws-samples/aws-open-data-satellite-lidar-tutorial

# Exit when error occurs
# set -e

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}


#reload bashrc
source $home/.bashrc

#check conda is installed
if ! command -v conda >/dev/null; then
    echo "Install first conda"
    exit 0
fi


# Create conda environment if name passed
echo "creating conda environment name=$ENV_NAME .."    
conda create -n lidar -y --channel conda-forge

# Activate the environment in Bash shell
conda activate lidar || conda init bash && source ~/.bashrc && conda activate lidar


# Install dependencies
conda instal ipykernel -y 
conda install --file conda-requirements.txt -y --channel conda-forge
pip install -r pip-requirements.txt
