#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#---------------Basic Parameters------------------
#aws cli profile 
export profile_name="tenac"
export email="yabebal@10academy.org"
export s3bucket="s3://all-tenx-system"
export s3_authorized_keys_path=""

echo "profile=$profile_name"

#application and proxy names
export root_name="cms" #name you give to your project in ecs env
export dns_namespace="cms.10academy.org"  ##This should be your domain 
export repo_name="JobModel" #not used for now
export app_name="${root_name}"  #-app
export proxy_name="${root_name}-proxy"
export log_group_name="/ecs/ecs-${root_name}-ssl"
echo "root_name=$root_name"

#---------------Github Parameters------------------
ssmgittoken="git_token_tenx"
gituname="10xac"

#use github actions or circleci
github_actions=false

#copy generated CI/CD config file to git repo
export push_cicd_template=false

#---------------AWS VPC Parameters------------------
##Export region and account
##Export key networking constructs
source ${scriptDir}/vpc_10academy.sh

#instance profile
IamInstanceProfile="arn:aws:iam::070096167435:instance-profile/Ec2InstanceWithFullAdminAccess"
sshKeyName="tech-ds-team"
AmazonImageId="ami-0c62045417a6d2199"
AwsInstanceType="t3.medium"

#---------------SSL Parameters------------------
# When true it means you have generated a letsencrypt
# or something similar ssl manually, and you have saved it in s3.
# Moreover, the lanuch template generation code/template is modified accordingly 
# such that the SSL certificate will be copied when an instance starts.
# The nginx will be enabled with the ssl configration and the ec2 instance
# can be accessed securely.
export copy_ssl_cert_froms3=true


#---------------Route53 Parameters------------------
#Route53 record setting
export create_route53_record=False
export route53RecordTemplate=template/r53-record-set-template.json

#---------------EC2 Parameters------------------
export ec2LaunchTemplate=template/ec2-launch-template.json

if [ -f $logoutputdir/alb_output_params.sh ]; then
    echo "ALB output file exists  ..."      
    source $logoutputdir/alb_output_params.sh
    export create_and_setup_alb=false
else
    export create_and_setup_alb=true
fi

if [ -f $logoutputdir/clt_output_params.sh ]; then
    echo "Launch template output file exists  ..."
    source $logoutputdir/clt_output_params.sh
    export create_launch_template=false
else
    export create_launch_template=true
fi

if [ -f $logoutputdir/output-create-auto-scaling-group.json ]; then
    echo "ASG output file exists  ..."    
    export create_and_setup_asg=false
else
    export create_and_setup_asg=true
fi

#-----------------ECS Parameters---------------
#create docker images locally and push them to ECR
export docker_push_proxy=false
export docker_push_test_app=false

export create_ecr_repo=false
if [ -f $logoutputdir/ecr_output_params.sh ]; then
    source $logoutputdir/ecr_output_params.sh
    if [ -z $aws_ecr_repository_url_app ]; then
        export create_ecr_repo=true
    fi
else
    export create_ecr_repo=true
fi

export create_ecs_cluster_and_task=false
export create_ecs_service=false

#ECS parameters
export app_container_name="${root_name}-container"  #-app
#export proxy_container_name="${root_name}-proxy-container"
export task_name="ecs-${root_name}-task"
export service_name="ecs-${root_name}-service"
export cluster="ecs-${root_name}-cluster"
export ECSLaunchType="EC2"
#"FARGATE"

#cpu and memory limit for an ecs docker container
#and template paths
export ecsTaskCpuUnit=1024
export ecsTaskMemoryUnit=2048
export ecsTaskTemplate=template/ecs-cms-task-template.json
export ecsServiceTemplate=template/ecs-ec2-service-template.json

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

