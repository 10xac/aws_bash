
# == key variable ==
cohort=b
week=12

if [ -z $group ]; then
   echo "please pass group number as environment variable e.g. export group=1"
   exit 0
fi   
group=${group}

name="group${group}"  #it is also a tag
dns_namespace="g${group}.10academy.org"
service="ec2"

# == AWS CLI profile ==
profile="ustenac"
ssmgittoken="git_token_tenx"
gitaccountname="10xac"

# == control variables 
team="CBtraining"
iam_users="fiker natnael" #provide the iam ds user as array here

echo "name=$name, profile=$profile"

# == define s3 path ==
s3bucket="10ac-cohort-${cohort}"
s3root="s3://${s3bucket}"

# == defines what to install ==
udcfile=cbw12.txt # comment out if you don't want to install compute packages
USERS_FILE="cohort-${cohort}-w${week}-g${group}.txt"
echo "Using: group=${group}, udcfile=${udcfile}, userfile=${USERS_FILE}"

# == often change ==
amiarc=arm64 #"arm64"    #nvidea
amios="ubuntu"
amifordocker=false

TYPE="c7g.4xlarge"   # instance type


# == security
IAM="B4EC2Role" 


# ==  set it once and seldom change ==
KEY="itrain-team-useast1"     # EC2 key pair name
COUNT=1         # how many instances to launch
EBS_SIZE=200    # root EBS volume size (GB)

#=== networking ===
#SG="sg-0606253fdd87db25e"  # (trainees_cluster)
#vpc="vpc-06cf87345b7d5fa44" #  (10xtraining) 
#subnetId="subnet-02990182ba1ce1a9f" # (training-subnet-1) 
#region="eu-west-1"

SG="sg-055b3aff51724bb3e"  # (ssh-only)
vpc="vpc-e7d8659d"  #(us-east1-training-vpc)
subnetId="subnet-ae247fa1"
region="us-east-1"
