# == key variable ==
batch=5

name="group3"  #it is also a tag
service="ec2"

# == AWS CLI profile ==
profile="tenac"
ssmgittoken="git_token_tenx"

# == control variables 
team="b5training"
iam_users=("mukuz" "mahlet" "bereket" "micheal" "zelalem") #provide the iam ds user as array here

echo "name=$name, profile=$profile"

# == define s3 path ==
s3bucket="10ac-batch-${batch}"
s3root="s3://${s3bucket}"

# == defines what to install ==
udcfile='g1.txt' # comment out if you don't want to install compute packages

# == often change ==
#TYPE="t3.small"   # EC2 instance type
TYPE="g5.4xlarge"   # GPU 1/24GB CPU 16/64GB

# == security
IAM="B4EC2Role" 


# ==  set it once and seldom change ==
KEY=" itrain-team-useast1"     # EC2 key pair name
COUNT=1         # how many instances to launch
EBS_SIZE=100    # root EBS volume size (GB)

#=== networking ===
#SG="sg-0606253fdd87db25e"  # (trainees_cluster)
#vpc="vpc-06cf87345b7d5fa44" #  (10xtraining) 
#subnetId="subnet-02990182ba1ce1a9f" # (training-subnet-1) 
#region="eu-west-1"

SG="sg-67e29322"  # (ssh-only)
vpc="vpc-e7d8659d"  #(us-east1-training-vpc)
subnetId="subnet-ae247fa1"
region="us-east-1"


