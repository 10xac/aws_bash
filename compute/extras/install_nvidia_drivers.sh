#! /bin/bash
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}


#reload bashrc
source $home/.bashrc


echo "installing nvidea driver .."
if command -v apt-get >/dev/null; then
    ubuntu-drivers autoinstall
    apt install nvidia-driver-440
    yum install -y gcc kernel-devel-$(uname -r)    
elif command -v yum >/dev/null; then
    yum install -y gcc kernel-devel-$(uname -r)

cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF

sh -c "echo 'GRUB_CMDLINE_LINUX=\"rdblacklist=nouveau\"' >>  /etc/default/grub"

grub2-mkconfig -o /boot/grub2/grub.cfg

aws s3 cp --recursive s3://ec2-linux-nvidia-drivers/latest/ .

chmod +x NVIDIA-Linux-x86_64*.run

/bin/sh ./NVIDIA-Linux-x86_64*.run
    
else
    echo "unknown os system.."
    exit
fi

echo "nvidea drivers are successfully installed .. reboot to complete setup .."

reboot


