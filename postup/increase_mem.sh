#ref:
# 1) https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/requesting-ebs-volume-modifications.html
# 2) https://codersathi.com/increase-ebs-volume-size-in-aws-ec2-instance/

if [ -z "$1" ]; then
    echo "Usage: bash increase_mem <volume-id> <size in GB> [profile_name]"
else
    vid=$1
fi


if [ -z "$2" ]; then
    echo "Usage: bash increase_mem <volume-id> <size in GB> [profile_name]"
else
    gb=$2
fi


#Now, the final step is to execute the resize2fs command for your root partition.
#In our example our root partition is /dev/nvme0n1p1
resize2fs ${root_partition}p1

#see the change
df -h

profile_name=${3:-tenac}


aws ec2 modify-volume --size $gb --volume-id $vid --profile $profile_name


#If you have mounted to your temp directory then execute following command to unmount it.
#If you haven’t mounted you can ignore this step
if $mount_tmp; then
    unmount /tmp
fi
