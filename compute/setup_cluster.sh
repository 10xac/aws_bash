#!/bin/bash

#reference for user_data script
#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

home=${ADMIN_HOME:-$(bash get_home.sh)}

if [ -d $home ]; then
    homeUser=$(basename $home)
else
    homeUser=`whoami`
fi

echo "current directory: `pwd`"
echo "home=$home"

#----------add variables to bashrc
if [ ! -z "$1" ]; then
    configfile="$1"
    if [ -f configs/$configfile ]; then
        configfile=configs/$configfile
    fi
fi

#if empty set default
if [ -z $configfile ]; then
    echo "********ERROR:  $configfile not found!**********"
    exit 0
fi
echo "setup_cluster config file: $configfile"

#copy userfile if it is in s3
if [[ $configfile == s3://* ]]; then
    aws s3 cp $configfile ./
    configfile=$(basename $configfile)
fi

#add
if [ $(dirname $configfile) == "." ]; then
    if [ ! -f $configfile ]; then
        configfile=configs/$configfile
    fi
    echo "full path appended to setup_cluster config file: $configfile"    
fi

if [ ! -f $configfile ]; then
    echo "ERROR: $configfile not found!"
fi


#sudo sh -c "sed -i '/^PasswordAuthentication/s/no/yes/' /etc/ssh/sshd_config"
touch envvars.sh

#read config file
sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$configfile" |
    while read line; do
        echo "--------- exporting to .bashrc line: $line ..."
        echo "export $line" >> $HOME/.bashrc
        echo "export $line" >> $home/.bashrc
        echo "export $line" >> envvars.sh        
    done
source $HOME/.bashrc

echo "following bashrc file sourced: "
cat $HOME/.bashrc

curdir=`pwd`
function copy_from_s3(){
    if [ $# -gt 1 ]; then    
        script=$1        
        fpath=$2
        echo ""
        echo "-------------------------"
        echo "copying $script from s3 ..."
        echo "-------------------------"
        echo ""        
        aws s3 cp $fpath/${script} ${curdir}/${script} || echo "failed to copy $script from S3"
    else
        echo "You must pass the filename to copy"
    fi
}

function run_script(){
    if [ $# -gt 0 ]; then    
        script=$1    
        if [ -f ${curdir}/${script} ]; then
            echo ""
            echo "*********************************"            
            echo "running $script ..."
            echo "*********************************"            
            if [ $# -gt 1 ]; then
                arg=$2
                bash ${curdir}/${script} $arg || echo "unable to run $script $arg"
            else
                bash ${curdir}/${script}  || echo "unable to run $script"
            fi
        fi
    fi    
}


#-------------mount s3 folder---------
source envvars.sh
echo "mounts3=$mounts3"
echo "addusers=$addusers"
echo "setupconda=$setupconda"
echo "installmlfow=$installmlfow"
echo "setupjhub=$setupjhub"
echo "setupjhub2=${setupjhub:-false}"
echo "setupjnb=setupjnb"

#setup cront to restart services
bash restart_services.sh 

#copy scripts
if ${mounts3:-true}; then
    script=s3mount/mount-s3fs.sh
    run_script ${script} install
    if [ -z "$(ls -A /mnt/$BUCKET)" ]; then
	echo "/mnt/$BUCKET is empty"	
    fi
fi
echo "installing other tasks once s3 is mounted .."
# #------------copy cred to current user-----
if ${addusers:-true}; then
    script=user/dshub_add_users.sh
    run_script ${script} $USERS_FILE
fi

# #----------install miniconda and create algos env
if ${setupconda:-true}; then
    script=conda/new_conda_setup.sh
    run_script ${script}
fi

# #----------install miniconda and create algos env
if ${installmlfow:-false}; then
    script=conda/install_mlflow.sh
    run_script ${script}
fi

# #----------create algos env
if ${algoscommon:-false}; then
    script=conda/install_algos_common.sh
    run_script ${script}
fi

# #----------install miniconda and create algos env
if ${bidAlgo:-false}; then
    script=conda/bid_algo.sh
    run_script ${script}
fi

# #---------install jupyterhub
if ${setupjhub:-true}; then
    script=jupyter/install_emr_jupyterhub.sh
    run_script ${script}
fi

#------configure jupyter
if ${setupjnb:-true}; then
    script=jupyter/notebook_config.sh
    run_script ${script}
fi

#--------install docker
if ${setupdocker:-true}; then
    script=extras/install_docker.sh 
    run_script ${script} $USERS_FILE
fi

#-------------mount s3 folder---------
#copy scripts
if ${unmounts3:-false}; then
    script=s3mount/mount-s3fs.sh
    run_script ${script} unmount 
fi

#--------install apps
if ${setupnvidea:-false}; then
    script=extras/nvidia_drivers_install.sh
    run_script ${script}
fi

if ${lidarapp:-false}; then
    script=apps/satellite-lidar/install_packages.sh
    run_script ${script}
fi

#make coda folder global writable
folder=${PYTHON_DIR:-/opt/miniconda}
if [ -d $folder ]; then
    sudo chmod 777 -R $folder
fi
