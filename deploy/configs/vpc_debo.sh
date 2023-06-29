
##Export region and account
export AccountId="969813551597"
#AccountId=$(aws sts get-caller-identity --query Account --output text --profile ${profile_name})  
export AWS_REGION=${DEBO_AWS_REGION:-"us-east-1"} # <- Your AWS Region
export account=$AccountId
export region=$AWS_REGION
echo "account=$account"
echo "region=$region"

##Export key networking constructs
#Subsitute these values with your VPC subnet ids
export private_subnet1="subnet-0aa8d6eff93cc9b36" #us-east-1a (NOT private)
export private_subnet2="subnet-00cc84abb5e5dd357" #us-east-1c (NOT private
export public_subnet1="subnet-09021022b346acd18" #us-east-1b (public)
export public_subnet2="subnet-0db9bda7dd08524f7" #us-east-1d (public)
export sgserver="sg-00116b3c9a00766c2" #allow connection from ALBs and SSH only
export sg=$sgserver
export sgalb="sg-096b592d2feafd693"   ##allow connection from  ssh/http/https All 0.0.0.0/0
export vpcId="vpc-0bfb689a944eb79b6" # (debo-vpc) <- Change this to your VPC id
echo "vpcid=$vpcId"

#instance profile
export IamInstanceProfile="arn:aws:iam::969813551597:instance-profile/EC2DockerS3Role"

#--------------------------------------------------------------------##
#---! DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !---------
export create_acm_certificate=false
#this is for *.adludio.com
certificateArn=arn:aws:acm:us-east-1:969813551597:certificate/265cf81c-e7c4-41df-b98a-c8a6bc29d746
#--------------------------------------------------------------------##

