#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
entrydir=`pwd`
export scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

deployDir=$(dirname $scriptDir)
cd $deployDir

#---------------Basic Parameters------------------
#load the right vpc parameters 
source ${scriptDir}/vpc_10academy.sh

#aws cli profile
export profile_name="tenac"
export email="yabebal@10academy.org"
#
export ssmgittoken="git_token_tenx"
export gituname="10xac"
#
export sshKeyName="tech-ds-team"
export s3bucket="s3://tenx-airflow-dags"
export s3MountBucket=
export s3_cred_path="s3://10ac-team/credentials"
export s3_authorized_keys_path="mahlet/authorized_keys micheal/authorized_keys bereket/authorized_keys"
#
echo "profile=$profile_name"

#extra user_data for ec2
export extrauserdata="user_data/fix_redis.sh user_data/mount-s3fs.sh user_data/run_build.sh user_data/add_ip_r53.sh"
export ec2launch_install_docker=true

#application and proxy names
export root_name="airflow" #name you give to your project in ecs env
export dns_namespace="airflow.10academy.org"  ##This should be your domain 
export repo_name="airflow-docker-setup" #not used for now 
export app_name="${root_name}"  #-app
export proxy_name="${root_name}-proxy"
export log_group_name="/ecs/ecs-${root_name}-ssl"
echo "root_name=$root_name"
echo "dns=$dns_namespace"

#cost instance type
#https://www.instance-pricing.com/provider=aws-ec2/region=eu-west-1/
#check this for diff TLS 1.2 vs TLS 1.3 https://bidhankhatri.com.np/system/enable-tls-1.3/
#export AwsImageId="ami-0258eeb71ddf238b3"  #Ubuntu 21.10 sup[p
#export AwsImageId="ami-0c62045417a6d2199"  #amazon linux - does not support TLS V1.3
#export AwsImageId="ami-08a35b8c2ae512dee"  #us east 1, Ubuntu 22.04, ARM64
export AwsImageId="ami-084500a7f52db24ed" #eu-west-1, Ubuntu 22.04, ARM64
export AwsInstanceType="t4g.large"   #"m6g.large"  #t3.large
export EbsVolumeSize=60
     
export ecsTaskPortMapList=8080
export ecsTaskFromTemplate=False
export ecsTaskTemplate=

#ecs service params
export ecsContainerPort=8080 #The port on the container to associate with the load balancer
export ecsDesiredCount=0
export ecsServiceTemplate=template/ecs-ec2-service-template.json

#---------------Github Parameters------------------

#use github actions or circleci
export github_actions=false

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
export copy_ssl_cert_froms3=true
export setup_nginx=false

#---------------Route53 Parameters------------------
#Route53 record setting
export create_route53_record=False
export route53RecordTemplate=template/r53-record-set-template.json

#---------------EC2 Parameters------------------
setupec2=true

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
export create_ecr_repo=false

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
