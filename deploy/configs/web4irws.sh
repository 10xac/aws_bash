#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
entrydir=`pwd`
export scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

deployDir=$(dirname $scriptDir)
#echo "Beginning of config file: chaning working director to: $entrydir"
cd $deployDir

#---------------Basic Parameters------------------
#load the right vpc parameters 
source ${scriptDir}/vpc_debo.sh

#aws cli profile
export region="us-east-1"
export profile_name="debo"
export email="4irworkspaces@gmail.com"
#
export ssmgittoken="git/token/yabi"
export gituname="debospaces"
#
export sshKeyName="dsde-debo-key-pair"
export s3bucket="s3://debo-team/"
export s3MountBucket=
export s3_authorized_keys_path=
#"s3://debo-team/credentials/zelalem/authorized_keys"
echo "profile=$profile_name"

#extra user_data for ec2
export extrauserdata="user_data/install_ecs_agent.sh"
export ec2launch_install_docker=true

#application and proxy names
export ENV=${ENV:-prod}
export root_name="debo-cms" #name you give to your project in ecs env
export rootdns=4irworkspaces.com
export certdnsname="${root_name}.${rootdns}"
export s3certpath=${s3bucket}/ssl-certs/${root_name}
export repo_name="debo-cms" #used to check out git repo
export repo_branch="main"
#
export dnsprefix=cms
if [ "$ENV" == "dev" ]; then
    export dnsprefix="dev-${dnsprefix}"
    export root_name="dev-$root_name"
    export repo_branch="dev"    
elif [ "$ENV" == "stag" ]; then
    export dnsprefix="staging-${dnsprefix}"
    export root_name="staging-$root_name"
    export repo_branch="staging"
fi

export dns_namespace="${dnsprefix}.${rootdns}"  ##This should be your domain 
export app_name="${root_name}"  #-app
export proxy_name="${root_name}-proxy"
export log_group_name="/ecs/ecs-${root_name}-ssl"
echo "ENV=$ENV"
echo "root_name=$root_name"
echo "dns=$dns_namespace"

#check this for diff TLS 1.2 vs TLS 1.3 https://bidhankhatri.com.np/system/enable-tls-1.3/
amiarc="amd64"    #
echo "Fetching latest Ubuntu AMI of type ${amiarc} .."
amipath="/aws/service/canonical/ubuntu/server/focal/stable/current/${amiarc}/hvm/ebs-gp2/ami-id"
#                                                                                                                                                        
echo "using amipath=$amipath"
if $(curl -s -m 5 http://169.254.169.254/latest/dynamic/instance-identity/document | grep -q availabilityZone) ; then
    auth="--region $region"
else
    auth="--profile ${profile_name} --region $region"
fi

AMI=$(aws ssm get-parameters --names $amipath \
          --query 'Parameters[0].[Value]' \
          --output text $auth )

echo "using AMI-ID=$AMI"
export AwsImageId=$AMI  #Ubuntu latest



export AwsInstanceType="t3.micro"
export EbsVolumeSize=30
     
export ecsTaskPortMapList=1337  #all ports to expose
export ecsTaskFromTemplate=False
export ecsTaskTemplate=

#ecs service params
export ecsContainerPort=1337 #The port on the container to associate with the load balancer
export ecsDesiredCount=0
export ecsServiceTemplate=template/ecs-ec2-service-template.json

#---------------Github Parameters------------------
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
export copy_ssl_cert_froms3=true
export setup_nginx=true

#---------------EC2 Parameters------------------
setup_ec2=true


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

#---------------Route53 Parameters------------------
#Route53 record setting
export create_route53_record=False
export route53RecordTemplate=template/r53-record-set-template.json

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
export ecsTaskExecutionRoleArn="arn:aws:iam::$account:role/ECSTaskExecutionRole"
export ecsTaskRoleArn="arn:aws:iam::$account:role/ECSTaskRole"

export params_file="$scriptDir/$0"

#return to the initial running directory path
#echo "End of config file: chaning working director to: $entrydir"
cd $entrydir

