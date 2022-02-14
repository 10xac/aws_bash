#jupyterhub.service
#Ref
#  https://pythonforundergradengineers.com/add-google-oauth-and-system-service-to-jupyterhub.html

#set -e

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}


# Parse Inputs. This is specific to this script, and can be ignored
# -----------------------------------------------------------------
JUPYTER_PASSWORD="jupyter"
EXTRA_CONDA_PACKAGES=""
JUPYTER="true"

# arguments can be set with create cluster
BUCKET=${BUCKET:-"/mnt"}
PYTHON_DIR=${PYTHON_DIR:-/opt/miniconda}
NOTEBOOK_DIR=${NOTEBOOK_FOLDER:-"$/opt/notebooks"}

# install s3fs
if [ ! -d /mnt/$BUCKET ]; then
    source mount-s3fs.sh install
fi

### Install Jupyter Notebook with conda and configure it.
echo "installing python libs in master"

# ------------------------------------------------------------
# 2. prepare folder and install libraries

## create a user account that will be used to run JupyterHub. Here we’ll use jupyterhub
if [ ! -d "/home/jupyterhub" ]; then
    sudo adduser jupyterhub
fi
echo "You may need to add jupyterhub user in the sudo group: https://linuxhint.com/centos_add_users_sudoers/"

## Software files
sudo mkdir -p /opt/jupyterhub
sudo chown -R jupyterhub /opt/jupyterhub
sudo chmod -R 777 /opt/jupyterhub

# Runtime files
sudo mkdir -p /var/jupyterhub
sudo chown -R jupyterhub /var/jupyterhub
sudo chmod -R 777 /var/jupyterhub

#log files
sudo mkdir -p /var/log/jupyter
sudo chmod -R 777 /var/log/jupyter

## Configuration files
sudo mkdir -p /etc/jupyterhub
sudo chown -R jupyterhub /etc/jupyterhub

#jupyter kernel space
sudo mkdir -p /usr/local/share/jupyter
sudo chmod 777 -R /usr/local/share/jupyter

# -----------------------------------------------------------------------------
# 3. Install jupyter notebook server and dependencies
echo 'export PATH="${PYTHON_DIR}/bin:$PATH"' | sudo tee -a /root/.bashrc

sudo su -c "source /root/.bashrc"

# -----------------------------------------------------------------------------
source ~/.bashrc

# echo "Installing Jupyter"
conda install \
      -c conda-forge \
      -y \
      -q \
      notebook \
      jupyterhub \
      jupyterlab \
      ipywidgets \
      ipykernel \
      nb_conda_kernels \
      jupyter-server-proxy 

jupyter serverextension enable jupyterlab

# -----------------------------------------------------------------------------
# 4.  Configure basic JupyterHub installation and see if everything works.

cat <<EOF > /tmp/conf 
#!/usr/bin/env bash

export PATH="${PYTHON_DIR}/bin:$PATH"
cd /var/jupyterhub
jupyterhub -f /etc/jupyterhub/jupyterhub_config.py
EOF
sudo mv /tmp/conf /opt/jupyterhub/start-jupyterhub



# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------



# -----------------------------------------------------------------------------



# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------



# -----------------------------------------------------------------------------
