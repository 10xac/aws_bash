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
export profile_name="tenac"
export email="yabebal@10academy.org"
#
export ssmgittoken="git_token_tenx"
export gituname="10xac"
#
export sshKeyName="devops-tenx-useast1-keypair"
export s3bucket="s3://all-tenx-system"
#export BUCKET=   #if you want to mount another BUCKET
export s3_authorized_keys_path=
#"s3://debo-team/credentials/zelalem/authorized_keys"
echo "profile=$profile_name"

#

#extra user_data for ec2
export extrauserdata="user_data/mount-s3fs.sh user_data/run_build.sh"
export ec2launch_install_docker=true

#application and proxy names
export ENV=${ENV:-prod}

#
export repo_name="tenx-vdb" #used to check out git repo
export repo_branch="weaviate"   

pp=""
export root_name="${pp}${repo_branch}-vdb" #name you give to your project in ecs env
export rootdns=10academy.org

#
#---------------SSL Parameters------------------
# pregenerated ssl certificate path 
#export s3certpath="s3://10ac-team/ssl-certs/tenx_vdb"
export s3certpath="s3://all-tenx-system/ssl-certs/sectigo"

# parameters in nginx.conf
export ssldnsname= #what is in letsencrypt/live/<ssldnsname>
export nginxservername="vdb.10academy.org"  #what is in nginx conf

# existing SSL certificate will be copied when an instance starts.
export copy_ssl_cert_froms3=true

# The nginx will be enabled with the ssl configration and the ec2 instance
# can be accessed securely.
export setup_nginx=true

# used in the ssl generation script as well as to insert an A record in R53 
export dns_namespace="${rootdns}"  ##This should be your domain - DNS name of the server 
export dns_ssl_list="vdb.${rootdns} vdbx.${rootdns} vdby.${rootdns} vdbz.${rootdns} weaviate.${rootdns} milvus.${rootdns}"  ##gen ssl 

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



export AwsInstanceType="t3.small"
export EbsVolumeSize=30
     
export ecsTaskPortMapList=8080  #all ports to expose
export ecsTaskFromTemplate=False
export ecsTaskTemplate=

#ecs service params
export ecsContainerPort=8080 #The port on the container to associate with the load balancer
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

