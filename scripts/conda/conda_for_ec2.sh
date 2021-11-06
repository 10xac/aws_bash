set -e

#where to install conda
folder=${PYTHON_DIR:-/opt/miniconda}
home=${ADMIN_HOME:-$(bash ../get_home.sh)}
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#get miniconda
curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh
sudo bash /tmp/miniconda.sh -b -p $folder
rm /tmp/miniconda.sh

sudo chmod 777 -R $folder

cat <<EOF >> $home/.bashrc
export PATH="${folder}/bin:${PATH}"
alias pip=${folder}/envs/algos/bin/pip3
EOF

source $home/.bashrc
conda init bash
source $home/.bashrc

#create venv
conda install -c anaconda -y ipykernel
#conda create -n algos -y
#conda activate algos

#install common packages
conda install \
      -c conda-forge \
      -y \
      -q \
      numpy pandas boto3 scipy \
      matplotlib seaborn plotly \
      sqlalchemy pip 


