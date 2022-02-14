#--------------------------------------------------------#
##------- Create two ECR repositories to store
#-------- the application and Envoy container images.
##------------------------------------------------------#

echo "creating ECR repository with the following name and region: app_name=${app_name}; region=$region"
#Repository 1:
res=$(aws ecr create-repository \
    --repository-name ${app_name} \
    --region $region --profile ${profile_name})

echo $res > $logoutputdir/output-create-repository.json

# *************** Repository 2: this feature is depreciated *******
# ****** use https://github.com/FutureAdLabs/ecs-ssl-proxy.git ****
#aws ecr create-repository --repository-name ${proxy_name} \
#    --region $region --profile ${profile_name}
