
##Export region and account
export AccountId="536509993821"
#AccountId=$(aws sts get-caller-identity --query Account --output text --profile ${profile_name})  
export AWS_REGION=${AIQEM_AWS_REGION:-"us-east-1"} # <- Your AWS Region
export account=$AccountId
export region=$AWS_REGION
echo "account=$account"
echo "region=$region"

##Export key networking constructs
#Subsitute these values with your VPC subnet ids
export private_subnet1="subnet-0a35b25907dfb4697" #us-east-1a (NOT private)
export private_subnet2="subnet-0089bdf2ddb817e5e" #us-east-1c (NOT private
export public_subnet1="subnet-01287a3d04bca8ad0" #us-east-1b (public)
export public_subnet2="subnet-0075aa43311423738" #us-east-1d (public)
export sgserver="sg-0874cece70fab479e" #allow connection from ALBs and SSH only
export sg=$sgserver
export sgalb="sg-0874cece70fab479e"   ##allow connection from  ssh/http/https All 0.0.0.0/0
export vpcId="vpc-08affe26a8b12eb42" # (tenx-system-vpc) <- Change this to your VPC id
echo "vpcid=$vpcId"

#instance profile
export IamInstanceProfile="arn:aws:iam::536509993821:instance-profile/EC2DockerS3Role"

#--------------------------------------------------------------------##
#---! DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !---------
export create_acm_certificate=false
#this is for *.adludio.com
certificateArn=arn:aws:acm:us-east-1:536509993821:certificate/ad6f807f-79bc-49c4-b4e2-92df66d12d2f
#--------------------------------------------------------------------##

