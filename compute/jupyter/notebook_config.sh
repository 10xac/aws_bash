set -e

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}

if [[ "$OSTYPE" == "darwin"* ]]; then
    SEDOPTION="-i ''"
else
    SEDOPTION="-i "
fi

#get git secret
# GIT_SECRET=$(aws secretsmanager get-secret-value \
#                  --secret-id "yabi-git-token" \
#                  --query SecretString \
#                  --output text)

PYTHON_DIR=${PYTHON_DIR:-/opt/miniconda}

# extract BUCKET and FOLDER to mount from NOTEBOOK_DIR
NOTEBOOK_DIR=${NOTEBOOK_FOLDER:-"notebooks"}
NOTEBOOK_DIR="/mnt/${NOTEBOOK_DIR%/}/"
echo "notebook dir is: $NOTEBOOK_DIR"


#BUCKET=$(python -c "print('$NOTEBOOK_DIR'.split('//')[1].split('/')[0])")
#FOLDER=$(python -c "print('/'.join('$NOTEBOOK_DIR'.split('//')[1].split('/')[1:-1]))")
#echo "bucket '$BUCKET' folder '$FOLDER'"

#
SSL=false
SSL_OPTS="--no-ssl"
NOTEBOOK_DIR_S3=true
JUPYTER_PORT=8887
JUPYTER_PASSWORD=""
JUPYTER_LOCALHOST_ONLY=false
JUPYTER_HUB=true
JUPYTER_HUB_PORT=8007
JUPYTER_HUB_IP="0.0.0.0"
JUPYTER_HUB_DEFAULT_USER="jupyter"
NOTEBOOK_DIR_S3_S3NB=false
NOTEBOOK_DIR_S3_S3CONTENTS=false


# Create the cookie secret file and change permissions so only the jupyterhub user has access.
#      Here we’ll configure only a few fields:
#        * JupyterHub.bind_url: the public facing URL of the whole JupyterHub application.
#        * JupyterHub.db_url: the address that the JupyterHub database can be reached at.
#        * JupyterHub.cookie_secret_file: the location to store the cookie secret.

openssl rand -hex 32 > /tmp/rsec
sudo mv /tmp/rsec /opt/jupyterhub/jupyterhub_cookie_secret
sudo chmod 600 /opt/jupyterhub/jupyterhub_cookie_secret
sudo chown jupyterhub /opt/jupyterhub/jupyterhub_cookie_secret


sudo mkdir -p /var/log/jupyter
mkdir -p $home/.jupyter


filename="$home/.jupyter/jupyter_notebook_config.py"
if [ -f $filename ]; then
    mv $filename $filename.buckup
    touch ls $filename    
else
    touch ls $filename
fi

sed $SEDOPTION '/c.NotebookApp.open_browser/d' $filename
echo "c.NotebookApp.open_browser = False" >> $filename

if [ ! "$JUPYTER_LOCALHOST_ONLY" = true ]; then
sed $SEDOPTION '/c.NotebookApp.ip/d' $filename
echo "c.NotebookApp.ip='0.0.0.0'" >> $filename
fi

sed $SEDOPTION '/c.NotebookApp.port/d' $filename
echo "c.NotebookApp.port = $JUPYTER_PORT" >> $filename

if [ ! "$JUPYTER_PASSWORD" = "" ]; then
  sed $SEDOPTION '/c.NotebookApp.password/d' $filename
  HASHED_PASSWORD=$(python3 -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")
  echo "c.NotebookApp.password = u'$HASHED_PASSWORD'" >> $filename
else
  sed $SEDOPTION '/c.NotebookApp.token/d' $filename
  echo "c.NotebookApp.token = u''" >> $filename
fi
echo "c.Authenticator.admin_users = {'$JUPYTER_HUB_DEFAULT_USER'}" >> $filename
echo "c.LocalAuthenticator.create_system_users = True" >> $filename
#/usr/local/bin/s3fs -o allow_other -o iam_role=auto -o umask=0 -o use_cache=/mnt/s3fs-cache $BUCKET /mnt/$BUCKET
echo "c.NotebookApp.notebook_dir = '$NOTEBOOK_DIR'" >> $filename
echo "c.ContentsManager.checkpoints_kwargs = {'root_dir': '.checkpoints'}" >> $filename
echo "c.Spawner.default_url = '/lab'" >> $filename


echo "" >> $filename
echo "" >> $filename


echo "#----------------- jupyterhub config -------------" >> $filename
echo "c.JupyterHub.bind_url = 'http://:8007'" >> $filename
echo "c.JupyterHub.cookie_secret_file = '/opt/jupyterhub/jupyterhub_cookie_secret'" >> $filename
echo "c.JupyterHub.db_url = 'sqlite:////var/jupyterhub/jupyterhub.sqlite'" >> $filename
echo  "c.JupyterHub.extra_log_file = '/var/log/jupyter/jupyterhub.log'" >> $filename
echo "c.JupyterHub.pid_file = '/opt/jupyterhub/jupyter.pid'" >> $filename
echo "c.ConfigurableHTTPProxy.pid_file = '/opt/jupyterhub/jupyter-proxy.pid'" >> $filename

echo "" >> $filename

echo "try:" >> $filename
echo "  import os" >> $filename
echo "  from jupyterhub.spawner import LocalProcessSpawner" >> $filename
echo "  class MySpawner(LocalProcessSpawner):" >> $filename
echo "      def _notebook_dir_default(self):" >> $filename
echo "        path = c.NotebookApp.notebook_dir + '/' + self.user.name" >> $filename
echo "        if os.path.exists(c.NotebookApp.notebook_dir):" >> $filename
echo "          os.makedirs(path,exist_ok=True)" >> $filename
echo "                   " >> $filename
echo "        return path" >> $filename
echo "  c.JupyterHub.spawner_class = MySpawner" >> $filename 
echo "except:" >> $filename
echo "  print('jupyterhub module not found')" >> $filename

# change the password of the home user to JUPYTER_PASSWORD
if [ ! "$JUPYTER_PASSWORD" = "" ]; then
    sudo sh -c "echo '$JUPYTER_PASSWORD' | passwd --stdin $JUPYTER_HUB_DEFAULT_USER"
fi
  
sudo ln -sf ${PYTHON_DIR}/bin/jupyterhub /usr/bin/
sudo ln -sf ${PYTHON_DIR}/bin/jupyterhub-singleuser /usr/bin/
mkdir -p /mnt/jupyterhub
cd /mnt/jupyterhub
echo "Starting Jupyterhub"

function system_deamon()
{
    #for EMR 6
cat <<EOF > /tmp/jupyterhub.service
[Unit]
Description=JupyterHub
#After=syslog.target network.target

[Service]
Environment="PATH=${PYTHON_DIR}/bin:$PATH"
ExecStart=${PYTHON_DIR}/bin/jupyterhub -f $filename
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target

EOF
#
sudo mv /tmp/jupyterhub.service /etc/systemd/system/

sudo systemctl daemon-reload
sleep 5
sudo systemctl start jupyterhub
sleep 3
sudo systemctl status jupyterhub 
}

system_deamon || echo "starting jupyter in the background failed."


# cat << 'EOF' > /tmp/jupyter_logpusher.config
# {
#   "/var/log/jupyter/" : {
#     "includes" : [ "(.*)" ],
#     "s3Path" : "node/$instance-id/applications/jupyter/$0",
#     "retentionPeriod" : "5d",
#     "logType" : [ "USER_LOG", "SYSTEM_LOG" ]
#   }
# }
# EOF
# cat /tmp/jupyter_logpusher.config | sudo tee -a /etc/logpusher/jupyter.config
