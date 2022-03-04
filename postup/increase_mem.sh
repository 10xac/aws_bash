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

profile_name=${3:-tenac}

aws ec2 modify-volume --size $gb --volume-id $vid --profile $profile_name

