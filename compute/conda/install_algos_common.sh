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
      numpy pandas boto3 scipy \
      matplotlib seaborn plotly \
      sqlalchemy 
conda install -c anaconda -y ipykernel


#----------get git packages
#bash git-submodule.sh

git_token=$(aws secretsmanager get-secret-value \
    --secret-id yabi-git-token \
    --query SecretString \
    --output text --region ${region:-"eu-west-1"})

git clone https://${git_token}@github.com/FutureAdLabs/algos-common.git ${home}/algos-common


#install algos-common requirement
home=${ADMIN_HOME:-$(bash get_home.sh)}
cd ${home}/algos-common
source ~/.bashrc
conda activate algos 
conda install pip -y
pip3 install -r requirements.txt
pip3 install -e .
