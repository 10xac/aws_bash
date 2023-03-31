# == key variable ==
name="mlflow"  #it is also a tag

# == control variables 
team="dsteam"
iam_users=("nati" "rahel" "natanan") #provide the iam ds user as array here
service="ec2"

# == AWS CLI profile ==
profile="adludio"

# == defines what to install ==
udcfile='mlflow.txt' # comment out if you don't want to install compute packages

# == often change ==
TYPE="t3.small"   # EC2 instance type
#TYPE="m5.xlarge"   # EC2 instance type

# == security
#IAM="B4EC2Role" 
IAM="ecsInstanceRole" # EC2 IAM role name

# ==  set it once and seldom change ==
KEY="ml-box"     # EC2 key pair name
COUNT=1         # how many instances to launch
EBS_SIZE=50    # root EBS volume size (GB)

#=== networking ===
SG="sg-04c5be8b8c1e6d6ea"  # ds-team-ssh-access 
vpc="vpc-92fd7af4" #data-vpc
subnetId="subnet-ff24ffb7" #public-data-subnet-a
region="eu-west-1"

echo "name=$name, profile=$profile"

