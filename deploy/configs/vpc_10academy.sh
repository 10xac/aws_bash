
##Export region and account
export AccountId="070096167435"
#AccountId=$(aws sts get-caller-identity --query Account --output text --profile ${profile_name})  
export AWS_REGION=${TENX_AWS_REGION:-"eu-west-1"} # <- Your AWS Region
export account=$AccountId
export region=$AWS_REGION
echo "account=$account"
echo "region=$region"

##Export key networking constructs
#Subsitute these values with your VPC subnet ids
export private_subnet1="subnet-0b7a972e85a68aa39" #tenx-private-subnet-a
export private_subnet2="subnet-02850568031317e42" #tenx-private-subnet-b 
export public_subnet1="subnet-0439c82a696920eac" #tenx-public-subnet-a
export public_subnet2="subnet-0a7731a4b7f3da8f8" #tenx-public-subnet-a
export sgserver="sg-0f75fbfd58b0c43a8" #allow connection from ALBs and SSH only
export sg=$sgserver
export sgalb="sg-0dce493bb5001e95a"   ##allow connection from  ssh/http/https All 0.0.0.0/0
export vpcId="vpc-0e670b1bc65c6423e" # (tenx-system-vpc) <- Change this to your VPC id
echo "vpcid=$vpcId"

#--------------------------------------------------------------------##
#---! DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !---------
export create_acm_certificate=false
#this is for *.adludio.com
certificateArn=arn:aws:acm:eu-west-1:070096167435:certificate/bdcaf7f1-081b-44ce-a88c-a7163de2d78d
#--------------------------------------------------------------------##

