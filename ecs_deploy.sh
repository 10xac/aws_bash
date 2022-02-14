#!/usr/bin/bash

#
# Adapted from Ref:
#   https://aws.amazon.com/blogs/containers/maintaining-transport-layer-security-all-the-way-to-your-container-using-the-application-load-balancer-with-amazon-ecs-and-envoy/
#

#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
if [ $# -gt 0 ]; then
    source $1
else
    echo "Usage: ecs_deploy <path to params file>"
    exit 0
fi
echo "Loading variables from $1"
source $1 #many key variables returned


#---------------------------------------------------------#
### ----------- Change dir to deploy folder----------##
##-------------------------------------------------------#
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $scriptDir/deploy

#create log and config saving dirs
source create_conflog_dir.sh $root_name


#generate circleci
if $github_actions; then
    if [ -f template/github_actions.template ]; then    
        envsubst <template/github_actions.template>$configoutputdir/github_actions_config.yml
        echo "template/github_actions.template variables replaced and saved as $configoutputdir/github_actions_config.yml"    
    fi
else
    if [ -f template/circleci.template ]; then
        envsubst <template/circleci.template>$configoutputdir/circleci_config.yml
        echo "template/circleci.template variables replaced and saved as $configoutputdir/circleci_config.yml"
        #echo "------------ circleci header -------------"
        #head -n28 template/config.yml | tail -n+6
        #echo "-----------------------------------------"
    fi
fi

exit

#--------------------------------------------------------#
##------- Push CircleCI Config to the repository --------#
##------------------------------------------------------#

if $push_circleci_template ; then
    source push_circleci_template.sh $repo_name #no variables returned
fi

#--------------------------------------------------------#
##------- Create two ECR repositories to store
#-------- the application and Envoy container images.
##------------------------------------------------------#


if $create_ecr_repo ; then
    source create_ecr_repos.sh #no variables returned
fi

# push test image if requested
if $docker_push_test_app; then
    source push_test_images_to_ecr.sh
fi

#--------------------------------------------------------#
###-------- Create cluster and task definition -----##
##------------------------------------------------------#
echo "current dir: `pwd`"
if $create_ecs_cluster_and_task; then
    #no variables returned
    source create_ecs_cluster.sh 
fi

#--------------------------------------------------------#
###************** returns needed variables *************#
###-------- Certificate setup -----##
##------------------------------------------------------#

if $create_acm_certificate && [ -z $certificateArn ]; then
    echo "Getting ACM certificate ..."
    source acm_certificate_setup.sh  #returns needed variables
fi



#stop if variable is not set
if [ -z $certificateArn ]; then
    echo "certificateArn is not set"
    exit 0
fi
#--------------------------------------------------------#
###-------- Create the Application Load Balancer -----##
##------------------------------------------------------#

if $create_and_setup_alb; then
    if [ -z $loadbalancerArn ] || [ -z $targetGroupArn ]; then
        echo "Creating and setting up ALB  ..."        
        source create_alb.sh #returns needed variables
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
    source create_launch_template.sh
fi

if $create_and_setup_asg && [ $ECSLaunchType == "EC2" ]; then
    echo "Creating and setting up ASG  ..."        
    source create_asg.sh #no variable returned
fi

#--------------------------------------------------------#
###-------- Certificate ecs service -----##
##------------------------------------------------------#

if $create_ecs_service; then
    echo "Creating ECS service .."
    source create_ecs_service.sh 
fi


#--------------------------------------------------------#
###-------- --------Route53 Setup ---------------------##
##------------------------------------------------------#

if $create_record_set; then
    echo "Creating Route53 Record ..."
    source create_route53_recordset.sh 
fi

#--------------------------------------------------------#
##-------- Certificate setup -----##
#------------------------------------------------------#

# echo quit | openssl s_client -showcerts -servername ecs-encryption.awsblogs.info -connect ecs-encryption.awsblogs.info:443 > cacert.pem

# #Hit the service 
# curl --cacert cacert.pem https://ecs-encryption.awsblogs.info/service

