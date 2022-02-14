pip3 install botocore --upgrade || echo "unable to upgrade botocore"
function awscli_install(){
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    if [ -f /usr/bin/aws]; then
        sudo rm /usr/bin/aws || echo "unable to remove aws"
    fi    
    sudo ln -s /usr/local/bin/aws /usr/bin/aws
    rm -rf .aws
}

awscli_install  || echo "unable to install cli"
