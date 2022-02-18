#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#aws cli profile 
export profile_name="tenx"
export email="yabebal@10academy.org"
export s3bucket="s3://all-tenx-system"
export s3_authorized_keys_path=""

echo "profile=$profile_name"

#application and proxy names
export root_name="pjmatch" #name you give to your project in ecs env
export dns_namespace="pjmatch.10academy.org"  ##This should be your domain 
export repo_name="JobModel" #not used for now
export app_name="${root_name}"  #-app
export proxy_name="${root_name}-proxy"
export log_group_name="/ecs/ecs-${root_name}-ssl"
echo "root_name=$root_name"

#cpu and memory limit for an ecs docker container
export ecsTaskCpuUnit=1024
export ecsTaskMemoryUnit=2048

#use github actions or circleci
github_actions=true
ssmgittoken="git_token_tenx"
gituname="10xac"

##Export region and account
##Export key networking constructs
source ${scriptDir}/vpc_10academy.sh

#instance profile
IamInstanceProfile="arn:aws:iam::070096167435:instance-profile/Ec2InstanceWithFullAdminAccess"
sshKeyName="tech-ds-team"
AmazonImageId="ami-0c62045417a6d2199"
AwsInstanceType="t3.medium"

# make this false to generate letsencrypt ssl manually
# once ssl cert is generate, copy it to s3, and set
# the value here to true and update launch template
# to enable nginx ssl configration when an ec2 instance
# is launched
export copy_ssl_cert_froms3=true

#copy generated CI/CD config file to git repo
export push_cicd_template=false

#EC2
export create_and_setup_alb=true
export create_launch_template=true
export create_and_setup_asg=true

export loadbalancerArn=
export targetGroupArn=

#ECR images
export aws_ecr_repository_url_app=070096167435.dkr.ecr.eu-west-1.amazonaws.com/tenx:latest

#create docker images locally and push them to ECR
export docker_push_proxy=false
export docker_push_test_app=false

#ECS
export create_ecr_repo=false
export create_ecs_cluster_and_task=false
export create_ecs_service=false


#---! DO NOT CHANGE THIS UNLESS YOU KNOW WHAT YOU ARE DOING !---------
export create_acm_certificate=false
#this is for *.adludio.com
certificateArn=arn:aws:acm:eu-west-1:070096167435:certificate/bdcaf7f1-081b-44ce-a88c-a7163de2d78d


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
export AsgTemplateName="${root_name}-launch-template"
export AsgTemplateVersion=15

##Service name and domain to be used
echo "dns=$dns_namespace"
echo "ecs cluster=$cluster"


#ECS task execution IAM role
export ecsTaskExecutionRoleArn="arn:aws:iam::$account:role/ecsTaskExecutionRole"
export ecsTaskRoleArn="arn:aws:iam::$account:role/ECSTaskRole"

export params_file="$scriptDir/$0"

