#----------get git packages
region="eu-west-1"
git_token=$(aws secretsmanager get-secret-value \
    --secret-id git_token_tenx \
    --query SecretString \
    --output text --region $region  | cut -d: -f2 | tr -d \"})

                                                              
#where conda is installed conda
pydir=${PYTHON_DIR:-/opt/miniconda}
home=${ADMIN_HOME:-$(bash ../../get_home.sh)}
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


source $home/.bashrc
conda create -n pjmatch -y
conda activate pjmatch

cd $home
git clone https://${git_token}@github.com/10xac/JobModel.git
cd JobModel
pip3 install -r requirements.txt
