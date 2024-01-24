# == key variable ==


name="data-box"  #it is also a tag
dns_namespace="databox.ubongo.com"
service="ec2"

# == AWS CLI profile ==
profile="ubongo"
ssmgittoken="git_token_tic"
gitaccountname="ubongo-tenacious"

# == control variables 
team="dsde-team"
iam_users="dibora" #provide the iam ds user as array here

echo "name=$name, profile=$profile"

# == define s3 path ==
s3bucket="ubo-datateam-box"
s3root="s3://${s3bucket}"

# == defines what to install ==
udcfile="ubongo2.txt" # comment out if you don't want to install compute packages
USERS_FILE="ubongo2.txt"
echo "Using: udcfile=${udcfile}, userfile=${USERS_FILE}"

# == often change ==
amiarc="arm64"    #nvidea
amios="ubuntu"
amifordocker=false

#TYPE="m6g.2xlarge"   # EC2 instance type
TYPE="c7g.large"

# == security
IAM="EC2DSDERole" 


# ==  set it once and seldom change ==
KEY="dsde-ubongo-key-pair"     # EC2 key pair name 
COUNT=1         # how many instances to launch
EBS_SIZE=100    # root EBS volume size (GB)

#=== networking ===
SG="sg-05a16e27c00717fae"  # (ssh-only)
vpc="vpc-0c2141870d7e73204"  #(us-east-1 ubongo-vpc-dev)

#ubongo public subnets
#subnet-04c25c4f9179ade84 1d 
#subnet-0598d14aa993251dd 1e
#subnet-03dac05dc2b890bcf 1f

#ubongo private subnets
#subnet-0c11ad424682315d1 1a
#subnet-00de59bbfca6cfafd 1b
#subnet-0c11ad424682315d1 1c


subnetId="subnet-03dac05dc2b890bcf" 
region="us-east-1"
