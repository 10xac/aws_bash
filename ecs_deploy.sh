#!/usr/bin/bash

#
# Adapted from Ref:
#   https://aws.amazon.com/blogs/containers/maintaining-transport-layer-security-all-the-way-to-your-container-using-the-application-load-balancer-with-amazon-ecs-and-envoy/
#

#https://stackoverflow.com/questions/60122188/how-to-turn-off-the-pager-for-aws-cli-return-value
export AWS_PAGER=""

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "Starting from `pwd` dir .."

#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
if [ ! -z "$1" ]; then
    echo "Loading variables from $1"    
    source $1
else
    echo "Usage: ecs_deploy <path to params file>"
    exit 0
fi


#---------------------------------------------------------#
### ----------- Change dir to deploy folder----------##
##-------------------------------------------------------#
cd $deployDir
echo "Current working dir: $deployDir"



#--------------------------------------------------------#
##------- Generate and Push CI/CD Config to the repository --------#
##------------------------------------------------------#

#check which CI/CD config to write
if $github_actions ; then
    template=template/github-actions-template.yml
    fout=$configoutputdir/github_actions_config.yml    
else
    template=template/circleci-template.yml
    fout=$configoutputdir/circleci_config.yml
fi

#write template
if [ -f $template ]; then
    echo "Creating and setting up CI/CD config file  ..."            
    envsubst <${template}>$fout
    echo "$template variables replaced and saved as $fout"
fi

if $push_cicd_template ; then
    echo "Pushing CI/CD config to repo ..."            
    source push_cicd_template.sh ""
fi

#--------------------------------------------------------#
###-------- Create the Application Load Balancer -----##
##------------------------------------------------------#

if $create_and_setup_alb ; then
    if [ -z $loadbalancerArn ] || [ -z $targetGroupArn ]; then
        echo "Creating and setting up ALB  ..."        
        source create_alb.sh ""  #returns needed variables
    fi
fi


#stop if variables are not set
if [ -z $loadbalancerArn ] || [ -z $targetGroupArn ]; then
    exit 0    
fi

#--------------------------------------------------------#
###-------- Create the Application Auto Scaling Group -----##
##------------------------------------------------------#

if $create_launch_template ; then
    if [[ $AwsImageId == $AwsImageOurs ]]; then
        echo "Updating Launch Template from pre-made AMI ..."          
        source update_launch_template.sh ""    
    else
        echo "Creating and setting up Launch Template  ..."      
        source create_launch_template.sh "" #returns AsgId variables
    fi
fi

if $create_and_setup_asg && [ $ECSLaunchType == "EC2" ]; then
    echo "Creating and setting up ASG  ..."        
    source create_asg.sh "" #no variable returned
fi

#--------------------------------------------------------#
##------- Create two ECR repositories to store
#-------- the application and Envoy container images.
##------------------------------------------------------#

if $create_ecr_repo ; then
    echo "Creating ECR repo .."    
    source create_ecr_repos.sh "" #no variables returned
fi

# push test image if requested
if $docker_push_test_app; then
    echo "Pushing docker to ECS cluster .."
    source push_test_images_to_ecr.sh ""
fi

#--------------------------------------------------------#
###-------- Create cluster and task definition -----##
##------------------------------------------------------#
if $create_ecs_cluster_and_task; then
    echo "Creating ECS cluster .."
    #no variables returned
    source create_ecs_cluster.sh ""
fi

#--------------------------------------------------------#
###- Certificate setup: PLEASE SETUP WILD ACM CERTIFICATES --##
##------------------------------------------------------#

# if $create_acm_certificate && [ -z $certificateArn ]; then
#     echo "Getting ACM certificate ..."
#     source acm_certificate_setup.sh  "" #returns needed variables
# fi

# #stop if variable is not set
# if [ -z $certificateArn ]; then
#     echo "certificateArn is not set"
#     exit 0
# fi


#--------------------------------------------------------#
###-------- Certificate ecs service -----##
##------------------------------------------------------#

if $create_ecs_service; then
    echo "Creating ECS service .."
    source create_ecs_service.sh ""
fi


#--------------------------------------------------------#
###-------- --------Route53 Setup ---------------------##
##------------------------------------------------------#

if $create_route53_record; then
    echo "Creating Route53 Record ..."
    source create_route53_record.sh ""
fi

#--------------------------------------------------------#
##-------- Certificate setup -----##
#------------------------------------------------------#

# echo quit | openssl s_client -showcerts -servername ecs-encryption.awsblogs.info -connect ecs-encryption.awsblogs.info:443 > cacert.pem

# #Hit the service 
# curl --cacert cacert.pem https://ecs-encryption.awsblogs.info/service

#--------------------------------------------------------#
##-------- sync output folder to s3 -----##
#------------------------------------------------------#

outputdir=$(dirname $logoutputdir)
aws s3 cp $outputdir $s3bucket/aws_bash_output/$region/ --recursive \
    --region $region --profile $profile_name
