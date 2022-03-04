#ref: https://codersathi.com/increase-ebs-volume-size-in-aws-ec2-instance/

#see disk
lsblk

root_partition=${1:-/dev/nvme0n1}
mount_tmp=${2:-true}

#To avoid a No space left on the block device error, mount the temporary
#file system tmpfs to the /tmp mount point.
#This creates a 10 M tmpfs mounted to /tmp.
#(This is optional, but if you see the error in the next step you can execute the following script)
if $mount_tmp; then
    sudo mount -o size=10M,rw,nodev,nosuid -t tmpfs tmpfs /tmp
fi
#Now, execute the growpart command to grow the size of the root partition.
#Replace /dev/nvme0n1 with your root partition
sudo growpart $root_partition 1

#Now, execute the lsblk command and you will see the size changed
lsblk


#Now, the final step is to execute the resize2fs command for your root partition.
#In our example our root partition is /dev/nvme0n1p1
sudo resize2fs ${root_partition}p1

#see the change
df -h


#If you have mounted to your temp directory then execute following command to unmount it.
#If you haven’t mounted you can ignore this step
if $mount_tmp; then
    sudo unmount /tmp
fi
