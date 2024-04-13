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
source ${scriptDir}/vpc_useast1_10academy.sh

#aws cli profile
export region="us-east-1"
export profile_name="ustenac"
export email="yabebal@10academy.org"
#
export ssmgittoken="git_token_tenx"
export gituname="10xac"
#
export sshKeyName="devops-tenx-useast1-keypair"
export s3bucket="s3://all-tenx-system"
export s3MountBucket=
export s3_authorized_keys_path="s3://10ac-team/credentials/bereket/authorized_keys"
#
echo "profile=$profile_name"

#extra user_data for ec2
#export extrauserdata="user_data/mount-s3fs.sh user_data/run_build.sh"
export extrauserdata="user_data/mount-s3fs.sh user_data/install_ecs_agent.sh user_data/docker_run_ecr.sh"
export ecrimage="070096167435.dkr.ecr.us-east-1.amazonaws.com/dev-u2j-cms:latest"

export appkey=$(echo $RANDOM$RANDOM$RANDOM$RANDOM | base64 | head -c 30; echo)
export appkeysalt=$(echo $RANDOM$RANDOM$RANDOM$RANDOM | base64 | head -c 30; echo)
          
export dockerenv="--env DATABASE_HOST=u2jdb.cluster-crlafpfc5g5y.us-east-1.rds.amazonaws.com -v /mnt/all-tenx-system/src-dev-u2jcms:/opt/app/src -v /mnt/all-tenx-system/public-dev-u2jcms:/opt/app/public --env appkey=$appkey --env appkeysalt=$appkeysalt --env APP_KEYS=${appkey},${appkeysalt} --env API_TOKEN_SALT=$appkeysalt --env ADMIN_JWT_SECRET=$appkey"
export ec2launch_install_docker=true

#application and proxy names
export ENV=${ENV:-prod}

export repo_name="tenx-cms" #used to check out git repo
export repo_branch="u2jdev"

export root_name="u2jcms" #name you give to your project in ecs env
export rootdns=10academy.org

export dnsprefix=u2jcms
if [ "$ENV" == "dev" ]; then
    export dnsprefix="dev-${dnsprefix}"
    export root_name="dev-$root_name"
    export repo_branch="applydev"    
elif [ "$ENV" == "stage" ]; then
    export dnsprefix="dev-${dnsprefix}"
    export root_name="dev-$root_name"
    export repo_branch="applystage"
fi

export dns_namespace="${dnsprefix}.${rootdns}"  ##This should be your domain 

#---------------SSL Parameters------------------
# pregenerated ssl certificate path 
export s3certpath="s3://all-tenx-system/ssl-certs/sectigo"  #path to live/ folder 

# parameters in nginx.conf
export ssldnsname= #what is in letsencrypt/live/<ssldnsname>
export nginxservername=${dns_namespace}  #what is in nginx conf

# existing SSL certificate will be copied when an instance starts.
export copy_ssl_cert_froms3=true

# The nginx will be enabled with the ssl configration and the ec2 instance
# can be accessed securely.
export setup_nginx=true

# used in the ssl generation script as well as to insert an A record in R53 
export dns_ssl_list="tenx.${rootdns} dev-tenx.${rootdns} stage-tenx.${rootdns} prompts.${rootdns} dev-prompts.${rootdns} apply.${rootdns} dev-apply.${rootdns} agent.${rootdns} dev-agent.${rootdns}"  ##gen ssl 

#-------------- EC2 Instance Params --------------------
export app_name="${root_name}"  #-app
export proxy_name="${root_name}-proxy"
export log_group_name="/ec2/ec2-${root_name}-ssl"
echo "ENV=$ENV"
echo "root_name=$root_name"
echo "dns=$dns_namespace"

#check this for diff TLS 1.2 vs TLS 1.3 https://bidhankhatri.com.np/system/enable-tls-1.3/
amiarc="amd64"    #
echo "Fetching latest Ubuntu AMI of type ${amiarc} .."
amipath="/aws/service/canonical/ubuntu/server/focal/stable/current/${amiarc}/hvm/ebs-gp2/ami-id"
#                                                                                                                                                        
# echo "using amipath=$amipath"
# if $(curl -s -m 5 http://169.254.169.254/latest/dynamic/instance-identity/document | grep -q availabilityZone) ; then
#     auth="--region $region"
# else
#     auth="--profile ${profile_name} --region $region"
# fi

# AMI=$(aws ssm get-parameters --names $amipath \
#           --query 'Parameters[0].[Value]' \
#           --output text $auth )

AMI="ami-0a47704035ec5db19"  #ubuntu22-ecs-nginx-s3mount
echo "using AMI-ID=$AMI"
export AwsImageId=$AMI

export AwsInstanceType="t3.small"
if [ "$ENV" == "prod" ]; then
    export AwsInstanceType="t3.medium"
fi
export EbsVolumeSize=20
#----------
     
export ecsTaskPortMapList=1337  #all ports to expose
export ecsTaskFromTemplate=False
export ecsTaskTemplate=

#ecs service params
export ecsContainerPort=1337 #The port on the container to associate with the load balancer
export ecsDesiredCount=0
export ecsHealthTime=60
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

