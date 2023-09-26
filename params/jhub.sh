# == key variable ==


name="jhub"  #it is also a tag
dns_namespace="usjhub.10academy.org"
service="ec2"

# == AWS CLI profile ==
profile="tenac"
ssmgittoken="git_token_tic"
gitaccountname="10xac"

# == control variables 
team="tenx-team"
iam_users="bereket" #provide the iam ds user as array here

echo "name=$name, profile=$profile"

# == define s3 path ==
s3bucket="10ac-team"
s3root="s3://${s3bucket}"

# == defines what to install ==
udcfile="jhub.txt" # comment out if you don't want to install compute packages
USERS_FILE="jhub.txt"
echo "Using: udcfile=${udcfile}, userfile=${USERS_FILE}"

# == often change ==
amiarc="arm64"    #nvidea
amios="ubuntu"
amifordocker=false

#TYPE="m6g.2xlarge"   # EC2 instance type
TYPE="c7g.2xlarge"

# == security
IAM="EC2DockerS3Role" 


# ==  set it once and seldom change ==
KEY="devops-tenx-useast1-keypair"     # EC2 key pair name 
COUNT=1         # how many instances to launch
EBS_SIZE=100    # root EBS volume size (GB)

#=== networking ===
SG="sg-008f16fbbe2825c98"  # (from ALB and ssh-only)
vpc="vpc-0f3e364754e23d56e"  #(us-east-1 tenx-system-vpc)

#ubongo public subnets
#subnet-04c25c4f9179ade84 1d 
#subnet-0598d14aa993251dd 1e
#subnet-03dac05dc2b890bcf 1f

#ubongo private subnets
#subnet-0c11ad424682315d1 1a
#subnet-00de59bbfca6cfafd 1b
#subnet-0c11ad424682315d1 1c


subnetId="subnet-0f848816007d926e7" 
region="us-east-1"
