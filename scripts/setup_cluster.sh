#!/bin/bash

#reference for user_data script
#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

home=${ADMIN_HOME:-$(bash get_home.sh)}

if [ -d $home ]; then
    homeUser=$(basename $home)
else
    homeUser=`whoami`
fi

#----------add variables to bashrc
configfile="./variables.txt"
[ $# -gt 0 ] && [ -r "$1" ] && configfile="$1"

#copy userfile if it is in s3
if [[ $configfile == s3://* ]]; then
    aws s3 cp $configfile ./
    configfile=$(basename $configfile)
fi


#sudo sh -c "sed -i '/^PasswordAuthentication/s/no/yes/' /etc/ssh/sshd_config"

#read config file
sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$configfile" |
    while read line; do
        echo "export $line" >> ~/.bashrc           
    done
source ~/.bashrc


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
script=s3mount/mount-s3fs.sh
run_script ${script} install

#------------copy cred to current user-----
script=user/dshub_add_users.sh
run_script ${script}

#----------install miniconda and create algos env
script=conda/conda_for_ec2.sh
run_script ${script}

#---------install jupyterhub
script=jupyter/install_emr_jupyterhub.sh
run_script ${script}

#------configure jupyter
script=jupyter/notebook_config.sh
run_script ${script}

#--------install docker
script=extras/install_docker.sh
run_script ${script}

#--------install apps
script=apps/pjmatch/jobmodel.sh
run_script ${script}



