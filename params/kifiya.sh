# == key variable ==


name="ds-experiment"  #it is also a tag
dns_namespace="jupyter.kifiya.com"
service="ec2"

# == AWS CLI profile ==
profile="kifiya"
ssmgittoken="git_token_tic"
gitaccountname="10xac"

# == control variables 
team="dsde-team"
iam_users="dibora ephrem nebiyu yabi" #provide the iam ds user as array here

echo "name=$name, profile=$profile"

# == define s3 path ==
s3bucket="kft-dsteam-box"
s3root="s3://${s3bucket}"

# == defines what to install ==
udcfile="kifiya.txt" # comment out if you don't want to install compute packages
USERS_FILE="kifiya.txt"
echo "Using: udcfile=${udcfile}, userfile=${USERS_FILE}"

# == often change ==
amiarc="arm64"    #nvidea
amios="ubuntu"
amifordocker=false

#TYPE="m6g.4xlarge"   # EC2 instance type
TYPE="c7g.2xlarge"

# == security
IAM="Ec2DSDERole" 


# ==  set it once and seldom change ==
KEY="dsde-key-emr"     # EC2 key pair name
COUNT=1         # how many instances to launch
EBS_SIZE=100    # root EBS volume size (GB)

#=== networking ===
#SG="sg-0606253fdd87db25e"  # (trainees_cluster)
#vpc="vpc-06cf87345b7d5fa44" #  (10xtraining) 
#subnetId="subnet-02990182ba1ce1a9f" # (training-subnet-1) 
#region="eu-west-1"

SG="sg-03f49fcdeb509e291"  # (ssh-only)
vpc="vpc-04eedbe41ac02cac8"  #(us-east1-training-vpc)
subnetId="subnet-003f75c0e47f0b090"
region="us-east-1"

#private
# subnet 1a: subnet-002d16113b7c1d15d
# subnet 1b: subnet-06a7f1609a9a138a7

#public
# subnet 1a: subnet-003f75c0e47f0b090
# subnet 1b: subnet-028a9b53678a0bf64
