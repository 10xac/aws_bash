
##Export region and account
export AccountId="637423514962"
#AccountId=$(aws sts get-caller-identity --query Account --output text --profile ${profile_name})  
export AWS_REGION="us-east-1" # <- Your AWS Region
export account=$AccountId
export region=$AWS_REGION
echo "account=$account"
echo "region=$region"

##Export key networking constructs
#Subsitute these values with your VPC subnet ids
export private_subnet1="subnet-0f065173397105ace" #tenx-private-subnet-a
export private_subnet2="subnet-02b17c41cd472cad5" #tenx-private-subnet-b 
export public_subnet1="subnet-0043dbfbd3079524c" #tenx-public-subnet-a
export public_subnet2="subnet-0282a54af8e981ac5" #tenx-public-subnet-a
export sgserver="sg-0cee86a086b2e1bf9" #allow connection from ALBs and SSH only
export sg=$sgserver
export sgalb="sg-0b8749b37347c0aec"   ##allow connection from  ssh/http/https All 0.0.0.0/0
export vpcId="vpc-0544989b68b1880e0" # (tenx-system-vpc) <- Change this to your VPC id
echo "vpcid=$vpcId"

#instance profile
export IamInstanceProfile="arn:aws:iam::637423514962:instance-profile/EC2DockerS3Role"


#--------------------------------------------------------------------##
#---! DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !---------
export create_acm_certificate=false
#this is for *.adludio.com
certificateArn="arn:aws:acm:us-east-1:637423514962:certificate/8bd7c01d-75cf-47bb-9921-68cbf85c8222"

#--------------------------------------------------------------------##

