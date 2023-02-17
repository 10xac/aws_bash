#ref:
# 1) https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/requesting-ebs-volume-modifications.html
# 2) https://codersathi.com/increase-ebs-volume-size-in-aws-ec2-instance/

if [ -z "$1" ]; then
    echo "Usage: bash increase_mem <volume-id> <size in GB> [profile_name] [region]"
    exit
else
    vid=$1
fi


if [ -z "$2" ]; then
    echo "Usage: bash increase_mem <volume-id> <size in GB> [profile_name] [region]"
    exit
else
    gb=$2
fi

profile_name=${3:-tenac}
region=${4:-'eu-west-1'}

echo "command: aws ec2 modify-volume --size $gb --volume-id $vid --profile $profile_name --region $region"
aws ec2 modify-volume --size $gb --volume-id $vid --profile $profile_name --region $region
