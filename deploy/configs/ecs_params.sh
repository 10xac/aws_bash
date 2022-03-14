#ecs task params
if [ $AwsInstanceType == "t3.micro" ]; then
   export ecsTaskCpuUnit=512
   export ecsTaskMemoryUnit=512
elif [ $AwsInstanceType == "t3.small" ]; then
   export ecsTaskCpuUnit=1024
   export ecsTaskMemoryUnit=1024   
elif [ $AwsInstanceType == "t3.medium" ]; then
    export ecsTaskCpuUnit=2048
    export ecsTaskMemoryUnit=2048
else
    export ecsTaskCpuUnit=2048
    export ecsTaskMemoryUnit=2048
fi

#create docker images locally and push them to ECR
export docker_push_proxy=false
export docker_push_test_app=false

#create ECR repo
export create_ecr_repo=false

#ecs task and service
if [ -f $logoutputdir/ecr_output_params.sh ]; then
    echo "ECR repo output file exists  ..."    
    source $logoutputdir/ecr_output_params.sh
    if [ -z $aws_ecr_repository_url_app ]; then
        echo "** empty aws_ecr_repository_url_app=$aws_ecr_repository_url_app"
        export create_ecr_repo=${setup_ecs:-false}
    fi
else
    echo "$logoutputdir/ecr_output_params.sh file does not exist"
    export create_ecr_repo=${setup_ecs:-false}
fi

#create ECS cluster and register task
if [ -f $logoutputdir/output-register-ecs-task.json ]; then
    echo "ECS task register output file exists  ..."    
    export create_ecs_cluster_and_task=false
else
    echo "$logoutputdir/output-register-ecs-task.json does not exist"
    export create_ecs_cluster_and_task=${setup_ecs:-false}
fi


if [ -f $logoutputdir/output-create-service.json ]; then
    echo "ECS service create  output file exists  ..."    
    export create_ecs_service=false
else
    echo "$logoutputdir/output-create-service.json does not exist"
    export create_ecs_service=${setup_ecs:-false}
fi

#ECS parameters
export ecr_repo_name=${root_name}
export ecs_cluster_name="ecs-${root_name}-cluster"                      
export app_container_name="${root_name}-container"  #-app
#export proxy_container_name="${root_name}-proxy-container"
export task_name="ecs-${root_name}-task"
export service_name="ecs-${root_name}-service"
export ECSLaunchType="EC2"  #"FARGATE"
