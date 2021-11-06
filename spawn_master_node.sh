#Reference
#https://bytes.babbel.com/en/articles/2017-07-04-spark-with-jupyter-inside-vpc.html
#https://cloud-gc.readthedocs.io/en/latest/chapter03_advanced-tutorial/advanced-awscli.html

if [ $# -gt 0 ]; then
    name=$1
else
    name="pjmatch"
fi
if [ $# -gt 1 ]; then
    profile=$2
else
    profile="tenac"
fi


echo "name=$name, profile=$profile"
team="pjmatch"
ec2="yes"

# == often change ==
TYPE="c5.4xlarge"   # EC2 instance type

# ==  set it once and seldom change ==
SG="sg-0606253fdd87db25e"  # security group ID
KEY="tech-ds-team"     # EC2 key pair name
COUNT=1         # how many instances to launch
IAM="B4EC2Role" # EC2 IAM role name
EBS_SIZE=150    # root EBS volume size (GB)

#=== networking === 
vpc="vpc-06cf87345b7d5fa44" #10xtraining
subnetId="subnet-02990182ba1ce1a9f"

region="eu-west-1"


if [ $ec2 == "yes" ]; then
    #user data / bootstrap file
    fname='./ec2_user_data.sh'
    
    echo "Creating EC2 instance with $fname user_data script .."
    amipath="/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
    AMI=$(aws ssm get-parameters --names $amipath --query 'Parameters[0].[Value]' --output text)
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
else
    #user data / bootstrap file
    fname='ec2_user_data.sh'
    fpath="s3://all-tenx-system-logs/emr_cluster_setup/$fname"
    
    echo "Creating EMR cluster with $fname bootstrap file.."
    echo "path=$fpath"
    aws s3 cp $fname $fpath --profile $profile

    #aws emr create-default-roles --profile $profile
    
    #reference
    #https://docs.aws.amazon.com/cli/latest/reference/emr/create-cluster.html    
    aws emr create-cluster --name $name \
        --release-label emr-6.2.0 \
        --ebs-root-volume-size 60 \
        --ec2-attributes \
        KeyName=$KEY,SubnetId="subnet-26a2027c" \
        --use-default-roles \
        --applications Name=Spark \
        --log-uri 's3://all-tenx-system-logs/emrcluster/' \
        --tag name=$name team=$team \
        --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m5.xlarge InstanceGroupType=CORE,InstanceCount=1,InstanceType=m5.xlarge \
        --bootstrap-actions Name=$fname,Path=$fpath \
        --region eu-west-1 \
        --region $region \
        --profile $profile
fi

#        --instance-type m5.xlarge \

#https://docs.aws.amazon.com/cli/latest/reference/emr/create-cluster.html
    # InstanceProfile="EMR_EC2_DefaultRole",
    # --service-role "EMR_DefaultRole" \
    # --auto-scaling-role "EMR_AutoScaling_DefaultRole" \

#BidPrice=0.1,
#    InstanceGroupType=CORE,InstanceCount=0,InstanceType=m5.xlarge \    
