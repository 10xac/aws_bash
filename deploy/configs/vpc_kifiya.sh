

##Export region and account
export AccountId="923083696216"
#AccountId=$(aws sts get-caller-identity --query Account --output text --profile ${profile_name})  
export AWS_REGION=${TENX_AWS_REGION:-"us-east-1"} # <- Your AWS Region
export account=$AccountId
export region=$AWS_REGION
echo "account=$account"
echo "region=$region"

##Export key networking constructs
#Subsitute these values with your VPC subnet ids
export private_subnet1="subnet-002d16113b7c1d15d" #private-subnet-1a
export private_subnet2="subnet-06a7f1609a9a138a7" #private-subnet-1b 
export public_subnet1="subnet-003f75c0e47f0b090" #public-subnet-1a
export public_subnet2="subnet-028a9b53678a0bf64" #tenx-public-subnet-a
export sgserver="sg-03f49fcdeb509e291" #allow connection from ALBs and SSH only
export sg=$sgserver
export sgalb="sg-05fe25b896f0fbae8"   ##allow connection from  ssh/http/https All 0.0.0.0/0
export vpcId="vpc-04eedbe41ac02cac8" # (tenx-system-vpc) <- Change this to your VPC id
echo "vpcid=$vpcId"

#instance profile
export IamInstanceProfile="arn:aws:iam::923083696216:instance-profile/Ec2DSDERole"

#--------------------------------------------------------------------##
#---! DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !---------
export create_acm_certificate=false
#this is for *.adludio.com
certificateArn=
#--------------------------------------------------------------------##

