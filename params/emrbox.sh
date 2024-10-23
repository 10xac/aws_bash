# == key variable ==
name="jupyterhub"  #it is also a tag
service="emr"

# == AWS CLI profile ==
profile="tenx"

# == control variables 
team="dsteam"
iam_users=("yabi" "mahlet") #provide the iam ds user as array here

echo "name=$name, profile=$profile"

# == define s3 path ==
s3root="s3://10ac-team"

# == defines what to install ==
udcfile='params.txt' # comment out if you don't want to install compute packages

# == often change ==
#TYPE="t3.small"   # EC2 instance type
TYPE="c5.4xlarge"   # EC2 instance type

# == security
#IAM="B4EC2Role" 
IAM=" Ec2InstanceWithFullAdminAccess" # EC2 IAM role name

# ==  set it once and seldom change ==
KEY=" tech-ds-team"     # EC2 key pair name
COUNT=1         # how many instances to launch
EBS_SIZE=80    # root EBS volume size (GB)

#=== networking ===
SG="sg-0606253fdd87db25e"  # (trainees_cluster)
vpc="vpc-06cf87345b7d5fa44" #  (10xtraining) 
subnetId="subnet-02990182ba1ce1a9f" # (training-subnet-1) 
region="eu-west-1"



