#!/bin/bash 
#exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

region="eu-west-1"

home=$HOME

#----------get git packages
git_token=$(aws secretsmanager get-secret-value \
    --secret-id git_token_tenx \
    --query SecretString \
    --output text --region $region  | cut -d: -f2 | tr -d \"})


if command -v apt-get >/dev/null; then
    sudo apt-get update -y
    sudo apt-get install -y git emacs htop
    if [ -d /home/ubuntu ]; then
        home=/home/ubuntu
    fi
else
    sudo yum update -y 
    sudo yum install -y git emacs htop
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

#-------add ADMIN_HOME to be non-root admin
echo "export ADMIN_HOME=$home" >> ~/.bashrc
source ~/.bashrc


#--------tell git who you are
git config --global user.email "yabebal@gmail.com"
git config --global user.name "Yabebal Fantaye"

#--------update aws cli
pip3 install botocore --upgrade || echo "unable to upgrade botocore"
function awscli_install(){
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --update
    if [ -f /usr/bin/aws]; then
        sudo rm /usr/bin/aws || echo "unable to remove aws"
    fi    
    sudo ln -s /usr/local/bin/aws /usr/bin/aws
    rm -rf .aws
}
if [[ $(aws --version) = aws-cli/1.* ]]; then
    awscli_install  || echo "unable to install cli"
fi
                                             

cd $home
git clone https://${git_token}@github.com/10xac/aws_bash.git

cd aws_bash/scripts
bash setup_cluster.sh configs/volunteers.txt 

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

#---- install apps -----

#change approperiately 
# reqfolder=satellite-lidar
# envname=agritech
# if [ -f $home/aws_bash/$reqfolder/install_packages.sh ]; then
#     cd $home/trainees_aws_cluster/$reqfolder
#     bash install_packages.sh $envname
# fi

#

