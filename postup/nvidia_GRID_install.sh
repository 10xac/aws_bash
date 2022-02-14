#! /bin/bash

sudo yum install -y gcc kernel-devel-$(uname -r)

cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF

sudo sh -c "echo 'GRUB_CMDLINE_LINUX=\"rdblacklist=nouveau\"' >>  /etc/default/grub"

sudo grub2-mkconfig -o /boot/grub2/grub.cfg

aws s3 cp --recursive s3://ec2-linux-nvidia-drivers/latest/ .

sudo chmod +x NVIDIA-Linux-x86_64*.run

sudo /bin/sh ./NVIDIA-Linux-x86_64*.run

sudo reboot
