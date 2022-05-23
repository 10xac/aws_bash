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

#----------get git packages
#bash git-submodule.sh

# git_token=$(aws secretsmanager get-secret-value \
#     --secret-id yabi-git-token \
#     --query SecretString \
#     --output text --region ${region:-"eu-west-1"})

#git clone https://${git_token}@github.com/FutureAdLabs/algos-common.git ${home}/algos-common

# MLflow credentials
creds=$(aws secretsmanager get-secret-value --secret-id MLFLOW_DB_CREDS --query SecretString --output text --region ${region:-"eu-west-1"})
username=$(echo $creds | jq -r ".username")
password=$(echo $creds | jq -r ".password")
host=$(echo $creds | jq -r ".host")
engine=$(echo $creds | jq -r ".engine")
db=$(echo $creds | jq -r ".dbname")
port=$(echo $creds | jq -r ".port")

function system_deamon()
{
# for EMR 6
cat <<EOF > /tmp/algos_mlflow.service
[Unit]
Description=Algos_Mlflow
#After=syslog.target network.target

[Service]
Environment="PATH=${PYTHON_DIR}/bin:$PATH"
ExecStart=${PYTHON_DIR}/bin/mlflow server --host 0.0.0.0 --port 5000 \
--backend-store-uri ${engine}://${username}:${password}@${host}:${port}/${db}   
--default-artifact-root s3://ml-box-data/model_store
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target

EOF
#
sudo mv /tmp/algos_mlflow.service /etc/systemd/system/

sudo systemctl daemon-reload
sleep 5
sudo systemctl start algos_mlflow
sleep 3
sudo systemctl status algos_mlflow 
}

system_deamon || echo "starting jupyter in the background failed."

