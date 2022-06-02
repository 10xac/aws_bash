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
configfile="params.txt"
[ $# -gt 0 ] && [ -f "$1" ] && configfile="$1"

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

#read config file
sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$configfile" |
    while read line; do
        echo "export $line" >> ~/.bashrc           
    done
source ~/.bashrc

echo "following bashrc file sourced: "
cat ~/.bashrc

curdir=`pwd`
function copy_from_s3(){
    if [ $# -gt 1 ]; then    
        script=$1        
        fpath=$2
        echo "copying $script from s3 ..."
        aws s3 cp $fpath/${script} ${curdir}/${script} || echo "failed to copy $script from S3"
    else
        echo "You must pass the filename to copy"
    fi
}

function run_script(){
    if [ $# -gt 0 ]; then    
        script=$1    
        if [ -f ${curdir}/${script} ]; then
            echo "running $script ..."
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
#copy scripts
if ${mounts3:-true}; then
    script=s3mount/mount-s3fs.sh
    run_script ${script} install
fi

# #------------copy cred to current user-----
if ${addusers:-true}; then
    script=user/dshub_add_users.sh
    run_script ${script}
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
if ${setupjhub:-false}; then
    script=jupyter/install_emr_jupyterhub.sh
    run_script ${script}
fi

#------configure jupyter
if ${setupjnb:-false}; then
    script=jupyter/notebook_config.sh
    run_script ${script}
fi

#--------install docker
if ${setupdocker:-true}; then
    script=extras/install_docker.sh
    run_script ${script}
fi

#-------------mount s3 folder---------
#copy scripts
if ${unmounts3:-false}; then
    script=s3mount/mount-s3fs.sh
    run_script ${script} unmount 
fi

#--------install apps
if ${setupnvidea:-false}; then
    script=extras/install_nvidia_drivers.sh
    run_script ${script}
fi

#script=apps/pjmatch/jobmodel.sh
#run_script ${script}
