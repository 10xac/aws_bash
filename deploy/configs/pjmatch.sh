#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#aws cli profile 
export profile_name="tenx"
export email="yabebal@10academy.org"
echo "profile=$profile_name"

#application and proxy names
export root_name="pjmatch" #name you give to your project in ecs env
export dns_namespace="pjmatch.10academy.ch"  ##This should be your domain 
export repo_name="JobModel" #not used for now
export app_name="${root_name}"  #-app
export proxy_name="${root_name}-proxy"
export log_group_name="/ecs/ecs-${root_name}-ssl"
echo "root_name=$root_name"

#use github actions or circleci
github_actions=true
ssmgittoken="git_token_tenx"
gituname="10xac"


# make this false to generate letsencrypt ssl manually
# once ssl cert is generate, copy it to s3, and set
# the value here to true and update launch template
# to enable nginx ssl configration when an ec2 instance
# is launched
export copy_ssl_cert_froms3=true

#create docker images locally and push them to ECR
export docker_push_proxy=false
export docker_push_test_app=false

#EC2
export create_and_setup_alb=true
export create_launch_template=true
export create_and_setup_asg=true

export loadbalancerArn=
export targetGroupArn=

#ECR images
export aws_ecr_repository_url_app=070096167435.dkr.ecr.eu-west-1.amazonaws.com/tenx:latest

#ECS
export create_ecr_repo=false
export create_ecs_cluster_and_task=false
export create_ecs_service=false


#---! DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !---------
export create_acm_certificate=false
#this is for *.adludio.com
certificateArn=arn:aws:acm:eu-west-1:489880714178:certificate/5d1753e6-51a1-4363-9bc5-5203daa91872


#ECS parameters
export app_container_name="${root_name}-container"  #-app
#export proxy_container_name="${root_name}-proxy-container"
export task_name="ecs-${root_name}-task"
export service_name="ecs-${root_name}-service"
export cluster="ecs-${root_name}-cluster"
export ECSLaunchType="EC2"
#"FARGATE"

#loadbalance and autoscale
export alb="ecs-${root_name}-alb"
export AsgName="ecs-${root_name}-asg"
export AsgMinSize=1
export AsgMaxSize=1
export AsgDesiredSize=1
export AsgTemplateId="lt-05a9b012ef8d06e13"
export AsgTemplateName="${root_name}-launch-template"
export AsgTemplateVersion=15


##Export region and account
export AccountId="489880714178"
#AccountId=$(aws sts get-caller-identity --query Account --output text --profile ${profile_name})  
export AWS_REGION=${ADLUDIO_AWS_REGION:-"eu-west-1"} # <- Your AWS Region
export account=$AccountId
export region=$AWS_REGION
echo "account=$account"
echo "region=$region"

##Export key networking constructs
#Subsitute these values with your VPC subnet ids
export private_subnet1="subnet-df5a8197" #private-data-subnet-a 
export private_subnet2="subnet-f8e1f6a3" #private-data-subnet-b 
export public_subnet1="subnet-ff24ffb7" #public-data-subnet-a
export public_subnet2="subnet-92e0f7c9" #public-data-subnet-b
export sg="sg-152edb69"   ##open access SG for ALB ssh/http/https All 0.0.0.0/0
export vpcId="vpc-92fd7af4" # (data-vpc) <- Change this to your VPC id
echo "vpcid=$vpcId"

##Service name and domain to be used
echo "dns=$dns_namespace"
echo "ecs cluster=$cluster"


#ECS task execution IAM role
export ecsTaskExecutionRoleArn="arn:aws:iam::$account:role/ecsTaskExecutionRole"


export params_file="$scriptDir/$0"

