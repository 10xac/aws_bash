#! /bin/bash

# Ref:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/install-nvidia-driver.html

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}


#reload bashrc
source $home/.bashrc


echo "installing nvidea driver .."
if command -v apt-get >/dev/null; then
    sudo apt-get install -qq -y gcc make linux-headers-$(uname -r)

    cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF

    # Edit the /etc/default/grub file and add the following line
    sh -c "echo 'GRUB_CMDLINE_LINUX=\"rdblacklist=nouveau\"' >>  /etc/default/grub"    
    
elif command -v yum >/dev/null; then
    yum install -qq -y gcc kernel-devel-$(uname -r)
    
else
    echo "unknown os system.."
    exit
fi


# Rebuild the Grub configuration.
if command -v apt-get >/dev/null; then
    sudo update-grub
elif command -v yum >/dev/null; then    
    grub2-mkconfig -o /boot/grub2/grub.cfg
fi

# Download the GRID driver installation utility using the following command:
aws s3 cp --recursive s3://ec2-linux-nvidia-drivers/latest/ .

# Add permissions to run the driver installation utility using the following command.
chmod +x NVIDIA-Linux-x86_64*.run

# Run the self-install script as follows to install the GRID driver that you downloaded. 
/bin/sh ./NVIDIA-Linux-x86_64*.run -s

echo "nvidea drivers are successfully installed .. reboot to complete setup .."

reboot


