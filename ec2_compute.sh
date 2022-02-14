#Reference
#https://bytes.babbel.com/en/articles/2017-07-04-spark-with-jupyter-inside-vpc.html
#https://cloud-gc.readthedocs.io/en/latest/chapter03_advanced-tutorial/advanced-awscli.html

echo "Number passed arguments: $#"
if [ $# -gt 0 ]; then
   source $1
else
    echo "You must pass a configuration file that contains key parameters"
    exit 0
fi

fname="instance_user_data/${name}_user_data.sh"

echo "sed replacing config file and writing: ec2_user_data.sh ->  $fname"
sed 's|specfile=.*|specfile='"$udcfile"'|g' user_data.sh > $fname
sed  -i "" 's|iam_users=|iam_users='"${iam_users}"'|g' $fname


if [ "$service" == "ec2" ]; then
    
    echo "Creating EC2 instance with $fname user_data script .."
    if [ "${amiopt:-docker}" == "docker" ]; then
        echo "Fetching docker-optimised AWS Linux AMI"
        amipath=/aws/service/ecs/optimized-ami/amazon-linux-2/recommended
        AMI=$(aws ssm get-parameters --names $amipath --query 'Parameters[0].[Value]' --output text --profile $profile | jq -r '.image_id')        
    else
        echo "Fetching latest AWS Linux AMI"        
        amipath="/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
        AMI=$(aws ssm get-parameters --names $amipath --query 'Parameters[0].[Value]' --output text --profile $profile)        
    fi

    echo "using AMI-ID=$AMI"
    #profile: ecsInstanceRole
    
    aws ec2 run-instances --image-id $AMI \
        --instance-type $TYPE --count $COUNT \
        --key-name $KEY \
        --security-group-ids $SG \
        --subnet-id $subnetId \
        --ebs-optimized \
        --monitoring Enabled=true \
        --iam-instance-profile Name=$IAM \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name},{Key=team,Value=$team}]" \
        --user-data "file://$fname" \
        --block-device-mapping DeviceName=/dev/xvda,Ebs={VolumeSize=$EBS_SIZE} \
        --region $region \
        --profile $profile
	#        --instance-market-options '{"MarketType":"spot"}'
	#extra volume
    #        --block-device-mapping DeviceName=/dev/sda1,Ebs={VolumeSize=$EBS_SIZE} \
        exit 0
else
    echo "service is not set to EC2 in the config file .. doing nothing"
fi
