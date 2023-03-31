#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
export scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

deployDir=$(dirname $scriptDir)
cd $deployDir

#---------------Basic Parameters------------------
#load the right vpc parameters 
source ${scriptDir}/vpc_kifiya.sh

#aws cli profile
export profile_name="kifiya"
export email="yabebal@gettenacious.com"
export s3bucket="s3://kft-dsteam-box"
export s3_authorized_keys_path=""
echo "profile=$profile_name"

export sshKeyName="kft-dsteam-box"

#extra user_data for ec2
export extrauserdata=user_data/run_build.sh
export ec2launch_install_docker=true

#application and proxy names
export root_name="csengine" #name you give to your project in ecs env
export dns_namespace="csengine.kifiya.com"  ##This should be your domain 
export repo_name="kft-credit-scoring" #not used for now
export app_name="${root_name}"  #-app
export proxy_name="${root_name}-proxy"
export log_group_name="/ecs/ecs-${root_name}-ssl"
echo "root_name=$root_name"
echo "dns=$dns_namespace"


#check this for diff TLS 1.2 vs TLS 1.3 https://bidhankhatri.com.np/system/enable-tls-1.3/
export AwsImageId="ami-0258eeb71ddf238b3"  #Ubuntu 21.10 sup[p
export AwsInstanceType="t3.medium"
export EbsVolumeSize=60

#ecs task params
export ecsTaskCpuUnit=1024
export ecsTaskMemoryUnit=2048
export ecsTaskPortMapList=5000
export ecsTaskFromTemplate=False
export ecsTaskTemplate=

#ecs service params
export ecsContainerPort=5000 #The port on the container to associate with the load balancer
export ecsDesiredCount=0
export ecsServiceTemplate=template/ecs-ec2-service-template.json

#---------------Github Parameters------------------
export ssmgittoken="git_token_tenx"
export gituname="10xac"

#use github actions or circleci
export github_actions=true

#copy generated CI/CD config file to git repo
export push_cicd_template=false

#---------------Create output folder------------------
#create log and config saving dirs
source create_conflog_dir.sh ""
if [ -z $configoutputdir ]; then
    echo "ERROR: The necessary variable configoutputdir is not defined!"
    echo "check create_conflog_dir.sh"
    exit 0
fi

#---------------SSL Parameters------------------
# When true it means you have generated a letsencrypt
# or something similar ssl manually, and you have saved it in s3.
# Moreover, the lanuch template generation code/template is modified accordingly 
# such that the SSL certificate will be copied when an instance starts.
# The nginx will be enabled with the ssl configration and the ec2 instance
# can be accessed securely.
export copy_ssl_cert_froms3=false


#---------------Route53 Parameters------------------
#Route53 record setting
export create_route53_record=False
export route53RecordTemplate=template/r53-record-set-template.json

#---------------EC2 Parameters------------------
setupec2=false

export ec2LaunchTemplate=template/ec2-launch-template.json

#now load the common ec2 params
source ${scriptDir}/ec2_params.sh

#loadbalance and autoscale
export alb="ecs-${root_name}-alb"
export AsgName="ecs-${root_name}-asg"
export AsgMinSize=1
export AsgMaxSize=1
export AsgDesiredSize=1
export AsgTemplateName="${root_name}-launch-template"
export AsgTemplateVersion=1

#-----------------ECS Parameters---------------
setup_ecs=false

#now load the common ec2 params
source ${scriptDir}/ecs_params.sh

#create ECR repo
export create_ecr_repo=true

#ECS parameters
export ecr_repo_name=${root_name}
export ecs_cluster_name="ecs-${root_name}-cluster"                      
export app_container_name="${root_name}-container"  #-app
#export proxy_container_name="${root_name}-proxy-container"
export task_name="ecs-${root_name}-task"
export service_name="ecs-${root_name}-service"
export ECSLaunchType="EC2"  #"FARGATE"


#ECS task execution IAM role
export ecsTaskExecutionRoleArn="arn:aws:iam::$account:role/ecsTaskExecutionRole"
export ecsTaskRoleArn="arn:aws:iam::$account:role/ECSTaskRole"

export params_file="$scriptDir/$0"

#return to the initial running directory path
cd $entrydir

