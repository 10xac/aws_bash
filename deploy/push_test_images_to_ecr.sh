#--------------------------------------------------------#
###-------- Create an Envoy configuration file. -----##
###-------- Create and push docker images ----------##
##------------------------------------------------------#

## Login to ECR
aws ecr get-login-password --region $region --profile ${profile_name} \
    | docker login \
             --username AWS \
             --password-stdin https://${account}.dkr.ecr.${region}.amazonaws.com


# *************** Repository 2: this feature is depreciated *******
# ****** use https://github.com/FutureAdLabs/ecs-ssl-proxy.git ****
# if $docker_push_proxy; then    
#     #create envoy config and docker image
#     source create_proxy_envoy.sh #no variable returned
#     docker push ${aws_ecr_repository_url_proxy}
# fi

#create test app
echo "current dir: `pwd`"
source test_app_docker.sh  #no variable returned
docker push ${aws_ecr_repository_url_app}
