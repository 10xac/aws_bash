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

#activate conda
conda init bash
source $home/.bashrc

#create venv
conda create -n algos -y
conda activate algos

#install common packages
conda install \
      -c conda-forge \
      -y \
      -q \
      boto3 mysqlclient
      
conda install -c anaconda -y ipykernel
pip install mlflow


