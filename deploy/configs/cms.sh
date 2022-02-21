#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
export scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

deployDir=$(dirname $scriptDir)
cd $deployDir

#---------------Basic Parameters------------------
#aws cli profile 
export profile_name="tenac"
export email="yabebal@10academy.org"
export s3bucket="s3://all-tenx-system"
export s3_authorized_keys_path=""
echo "profile=$profile_name"

#extra user_data for ec2
export extrauserdata=user_data/cms.sh

#application and proxy names
export root_name="cms" #name you give to your project in ecs env
export dns_namespace="cms.10academy.org"  ##This should be your domain 
export repo_name="JobModel" #not used for now
export app_name="${root_name}"  #-app
export proxy_name="${root_name}-proxy"
export log_group_name="/ecs/ecs-${root_name}-ssl"
echo "root_name=$root_name"
echo "dns=$dns_namespace"

#---------------Create output folder------------------
#create log and config saving dirs
source create_conflog_dir.sh ""
if [ -z $configoutputdir ]; then
    echo "ERROR: The necessary variable configoutputdir is not defined!"
    echo "check create_conflog_dir.sh"
    exit 0
fi

#---------------Github Parameters------------------
export ssmgittoken="git_token_tenx"
export gituname="10xac"

#use github actions or circleci
export github_actions=true

#copy generated CI/CD config file to git repo
export push_cicd_template=false

#---------------AWS VPC Parameters------------------
##Export region and account
##Export key networking constructs
source ${scriptDir}/vpc_10academy.sh

#instance profile
export IamInstanceProfile="arn:aws:iam::070096167435:instance-profile/Ec2InstanceWithFullAdminAccess"
export sshKeyName="tech-ds-team"

#check this for diff TLS 1.2 vs TLS 1.3 https://bidhankhatri.com.np/system/enable-tls-1.3/
export AwsImageId="ami-0258eeb71ddf238b3"  #Ubuntu 21.10 sup[p
#export AwsImageId="ami-0c62045417a6d2199"  #amazon linux - does not support TLS V1.3
export AwsInstanceType="t3.medium"

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
    if [ -z $loadbalancerArn ] || [ -z $targetGroupArn ]; then
        echo "***Either ALB ARN or Target group ARN is missing."
        export create_and_setup_alb=true
    else
        export create_and_setup_alb=false
    fi
else
    echo "$logoutputdir/alb_output_params.sh does not exist"
    export create_and_setup_alb=true
fi

if [ -f $logoutputdir/clt_output_params.sh ]; then
    echo "Launch template output file exists  ..."
    source $logoutputdir/clt_output_params.sh
    export create_launch_template=false
else
    echo "$logoutputdir/clt_output_params.sh file does not exist"    
    export create_launch_template=true
fi

if [ -f $logoutputdir/output-create-auto-scaling-group.json ]; then
    echo "ASG output file exists  ..."    
    export create_and_setup_asg=false
else
    echo "$logoutputdir/output-create-auto-scaling-group.json does not exist"
    export create_and_setup_asg=true
fi

#loadbalance and autoscale
export alb="ecs-${root_name}-alb"
export AsgName="ecs-${root_name}-asg"
export AsgMinSize=1
export AsgMaxSize=1
export AsgDesiredSize=1
export AsgTemplateName="${root_name}-launch-template"
export AsgTemplateVersion=1

#-----------------ECS Parameters---------------
#create docker images locally and push them to ECR
export docker_push_proxy=false
export docker_push_test_app=false

#create ECR repo
export create_ecr_repo=false
if [ -f $logoutputdir/ecr_output_params.sh ]; then
    echo "ECR repo output file exists  ..."    
    source $logoutputdir/ecr_output_params.sh
    if [ -z $aws_ecr_repository_url_app ]; then
        echo "** empty aws_ecr_repository_url_app=$aws_ecr_repository_url_app"
        export create_ecr_repo=true
    fi
else
    echo "$logoutputdir/ecr_output_params.sh file does not exist"
    export create_ecr_repo=true
fi

#create ECS cluster and register task
if [ -f $logoutputdir/output-register-ecs-task.json ]; then
    echo "ECS task register output file exists  ..."    
    export create_ecs_cluster_and_task=false
else
    echo "$logoutputdir/output-register-ecs-task.json does not exist"
    export create_ecs_cluster_and_task=true    
fi

if [ -f $logoutputdir/output-create-service.json ]; then
    echo "ECS service create  output file exists  ..."    
    export create_ecs_service=false
else
    echo "$logoutputdir/output-create-service.json does not exist"
    export create_ecs_service=true
fi

#ECS parameters
export ecr_repo_name=${root_name}
export ecs_cluster_name="ecs-${root_name}-cluster"                      
export app_container_name="${root_name}-container"  #-app
#export proxy_container_name="${root_name}-proxy-container"
export task_name="ecs-${root_name}-task"
export service_name="ecs-${root_name}-service"
export ECSLaunchType="EC2"  #"FARGATE"

#ecs service params
export ecsContainerPort=1337 #The port on the container to associate with the load balancer
export ecsDesiredCount=0
export ecsServiceTemplate=template/ecs-ec2-service-template.json
#ecs task params
export ecsTaskCpuUnit=1024
export ecsTaskMemoryUnit=2048
export ecsTaskTemplate=template/ecs-cms-task-template.json



##Service name and domain to be used



#ECS task execution IAM role
export ecsTaskExecutionRoleArn="arn:aws:iam::$account:role/ecsTaskExecutionRole"
export ecsTaskRoleArn="arn:aws:iam::$account:role/ECSTaskRole"

export params_file="$scriptDir/$0"

