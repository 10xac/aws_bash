#!/bin/bash 
#exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

region="eu-west-1"
s3bucket='10ac-batch-5'


export HOME=${HOME:-"/root"}
home=$HOME

if command -v apt-get >/dev/null; then
    sudo apt-get update -qq -y
    sudo apt-get install -qq -y git emacs htop jq unzip
    if [ -d /home/ubuntu ]; then
        home=/home/ubuntu
    fi
else
    sudo yum update -qq -y
    sudo yum install -qq -y git emacs htop jq unzip
    if [ -d /home/centos ]; then
        home=/home/centos
    fi
    if [ -d /home/ec2-user ]; then
        home=/home/ec2-user
    fi    
fi

if [ -d /home/hadoop ]; then
    home=/home/hadoop
fi

#-------add path ADMIN_HOME to be non-root admin
echo "export PATH=/usr/bin:/usr/local/bin:$PATH" >> $HOME/.bashrc
echo "export PATH=/usr/bin:/usr/local/bin:$PATH" >> $home/.bashrc
#
echo "export ADMIN_HOME=$home" >> $HOME/.bashrc
echo "export ADMIN_HOME=$home" >> $home/.bashrc
source $HOME/.bashr

export SSM_GITTOKEN_NAME=yabi-git-token
echo "export SSM_GITTOKEN_NAME=${SSM_GITTOKEN_NAME}" >> $HOME/.bashrc
echo "export SSM_GITTOKEN_NAME=${SSM_GITTOKEN_NAME}" >> $home/.bashrc



#source ~/.bashrc

#--------update aws cli
pip3 install botocore --upgrade || echo "unable to upgrade botocore"
function awscli_install(){
    yum install unzip -y -qq
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -qq awscliv2.zip
    ./aws/install --update
    if [ -f /usr/bin/aws ]; then
        rm /usr/bin/aws || echo "unable to remove aws"
    fi    
    ln -s /usr/local/bin/aws /usr/bin/aws
    rm -rf .aws
}

if command -v aws >/dev/null; then
   if [[ $(aws --version) = aws-cli/1.* ]]; then
       awscli_install  || echo "unable to install cli"
   fi
else
   awscli_install  || echo "unable to install cli"     
fi

echo "changing working directory to: $home"
cd $home
echo "current director: `pwd`"

#--------tell git who you are
echo "config git email and name .."
git config --global user.email "yabebal@gmail.com"
git config --global user.name "Yabebal Fantaye"


#----------get git packages
echo "get git token from ssm .."
git_token=$(aws secretsmanager get-secret-value \
    --secret-id  ${SSM_GITTOKEN_NAME} \
    --query SecretString \
    --output text --region $region | cut -d: -f2 | tr -d \"{})

echo "git clone aws_bash .."
git clone https://${git_token}@github.com/10xac/aws_bash.git || echo "failed with git_token=$git_token"

## enable an iam user to ss
iam_users=
if (( ${#iam_users[@]} )); then
    for n in $iam_users; do
        echo "copying public key to authorized_keys for user=$n"
        aws s3 cp s3://${s3bucket}/credentials/${n}/authorized_keys pub_key || echo "sshkey for $n not found"
        if [ -f pub_key ]; then
            cat pub_key >> $home/.ssh/authorized_keys | echo "ERROR: can not copy authorization key from s3"
        fi
    done
fi

# if [ -f /mnt/$CREDROOTFOLDER/ssh/${n}_authorized_keys ]; then
#     sudo cp /mnt/$CREDROOTFOLDER/ssh/${n}_authorized_keys $HOME/.ssh/authorized_keys
# elif [ -f /mnt/$CREDROOTFOLDER/${n}/authorized_keys ]; then
#         sudo cp /mnt/$CREDROOTFOLDER/${n}/authorized_keys $HOME/.ssh/authorized_keys
# fi


specfile=""
echo "install spec file is:"
echo $specfile

if [ ! -z $specfile ]; then
    cd aws_bash/compute
    
    bash setup_cluster.sh $specfile 
    
    #copy all root environment to user
    if [ -f $HOME/.bashrc ]; then
        cat $HOME/.bashrc >> $home/.bashrc || echo "not possible"
    fi
    
    homeuser=$(basename $home)
    echo "HOME_USER=$homeuser"
    for dpath in '/opt/miniconda' ; do
        if [ -d $dpath ]; then
            chown -R $homeuser:$homeuser $dpath || echo "$homeuser can not own $dpath"
        fi
    done
else
    echo "Missing specfile path - it is a necessary argument when calling setup_cluster.py"
fi

#mv $home/aws_bash $HOME/
