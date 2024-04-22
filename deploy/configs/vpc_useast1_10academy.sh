
##Export region and account
export AccountId="070096167435"

#
export HOSTEDZONEID="Z034028834IXN0CQEMHZ9"

#AccountId=$(aws sts get-caller-identity --query Account --output text --profile ${profile_name})  
export AWS_REGION="us-east-1" # <- Your AWS Region
export account=$AccountId
export region=$AWS_REGION
echo "account=$account"
echo "region=$region"

##Export key networking constructs
#Subsitute these values with your VPC subnet ids
export private_subnet1="subnet-0942fc873f87298e0" #tenx-private-subnet-a
export private_subnet2="subnet-05b4850ce1a74eb39" #tenx-private-subnet-b 
export public_subnet1="subnet-0f848816007d926e7" #tenx-public-subnet-a
export public_subnet2="subnet-06b6b4f0179ad4dcb" #tenx-public-subnet-a
export sgserver="sg-008f16fbbe2825c98" #allow connection from ALBs and SSH only
export sg=$sgserver
export sgalb="sg-03de8c8ca2e8ef345"   ##allow connection from  ssh/http/https All 0.0.0.0/0
export vpcId="vpc-0f3e364754e23d56e" # (tenx-system-vpc) <- Change this to your VPC id
echo "vpcid=$vpcId"

#instance profile
export IamInstanceProfile="arn:aws:iam::070096167435:instance-profile/EC2DockerS3Role"
#"arn:aws:iam::070096167435:instance-profile/Ec2InstanceWithFullAdminAccess"

#--------------------------------------------------------------------##
#---! DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !---------
export create_acm_certificate=false
#this is for *.adludio.com
certificateArn=arn:aws:acm:us-east-1:070096167435:certificate/6a164239-c77f-4f50-83ca-840091012dc5
#--------------------------------------------------------------------##

