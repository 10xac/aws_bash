###-----Define necessary environment variables if passed -----##
##------------------------------------------------------#
if [ ! -z "$1" ]; then    
    echo "Loading variables from $1"
    source $1 #many key variables returned
    source create_conflog_dir.sh ""
    echo "confdir=$configoutputdir"
    echo "logdir=$logoutputdir"    
fi

#--------------------------------------------------------#
##------- Create two ECR repositories to store
#-------- the application and Envoy container images.
##------------------------------------------------------#

echo "creating ECR repository with the following name and region: app_name=${app_name}; region=$region"
#Repository 1:

res=$(aws ecr describe-repositories \
          --repository-names ${ecr_repo_name} \
          --region $region  \
          || echo "None")

if (( ${#res[@]} )); then #not empty
    repoexist=$(echo $res | jq -r '.repositories | length>0')
else
    echo "ECR repo does not exist .. creating one"
    repoexist=false    
fi

repoexist=${repoexist:-false}

if $repoexist ; then
    echo "ECR repo exists"    
   ecrRepoArn=$(echo $res | jq -r '.repositories[0].repositoryArn') 
else
    res=$(aws ecr create-repository \
              --repository-name ${ecr_repo_name} \
              --region $region \
              --profile ${profile_name})
    
    res=$(aws ecr describe-repositories \
              --repository-names ${ecr_repo_name} \
              --region $region )

    ecrRepoArn=$(echo $res | jq -r '.repositories[0].repositoryArn')
fi

echo "export aws_ecr_repository_url_app=$ecrRepoArn"
echo $res > $logoutputdir/output-create-repository.json
echo "export aws_ecr_repository_url_app=$ecrRepoArn" > $logoutputdir/ecr_output_params.sh
source $logoutputdir/ecr_output_params.sh


# *************** Repository 2: this feature is depreciated *******
# ****** use https://github.com/FutureAdLabs/ecs-ssl-proxy.git ****
#aws ecr create-repository --repository-name ${proxy_name} \
#    --region $region --profile ${profile_name}
