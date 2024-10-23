# == key variable ==
name="certbot"  #it is also a tag
service="ec2"

# == AWS CLI profile ==
profile="tenx"

# == control variables 
team="dev"
iam_users=("yabi" "mahlet") #provide the iam ds user as array here

echo "name=$name, profile=$profile"

# == define s3 path ==
s3root="s3://10ac-team"

# == defines what to install ==
udcfile='params.txt' # comment out if you don't want to install compute packages

# == often change ==
#TYPE="t3.small"   # EC2 instance type
TYPE="t3.micro"   # EC2 instance type

# == security
#IAM="B4EC2Role" 
IAM=" Ec2InstanceWithFullAdminAccess" # EC2 IAM role name

# ==  set it once and seldom change ==
KEY=" tech-ds-team"     # EC2 key pair name
COUNT=1         # how many instances to launch
EBS_SIZE=80    # root EBS volume size (GB)

#=== networking ===
SG="sg-0dce493bb5001e95a"  #  (launch-wizard-8)
vpc="vpc-0e670b1bc65c6423e" #  (upskill-vpc-VPC) 
subnetId="subnet-0439c82a696920eac" # (upskill-vpc-Public-A) 
region="eu-west-1"



