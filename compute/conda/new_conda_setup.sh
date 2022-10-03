set -e

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}

#where to install conda
folder=${PYTHON_DIR:-/opt/miniconda}


#get miniconda
if [[ $(uname -m) == *arch64* ]]; then
    curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh -o /tmp/miniconda.sh    
else
    curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh
fi
sudo bash /tmp/miniconda.sh -b -p $folder
rm /tmp/miniconda.sh


$folder/bin/conda update -n base -c defaults conda

cat <<EOF >> $home/.bashrc
export PATH="${folder}/bin:${PATH}"
EOF

source $home/.bashrc
$folder/bin/conda init bash
source $home/.bashrc

#create venv
$folder/bin/conda install -c anaconda -y ipykernel
