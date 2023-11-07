##------------------------------------------------------#
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
###-------- Create cluster and task definition -----##
##------------------------------------------------------#
set -e

#Create a task definition with container definitions.
#Substitute the environment variables, create a log group,
#an ECS cluster, and register the task definition.
fout=$configoutputdir/ecs_task_def.json


cat <<EOF > $fout
{
  "taskRoleArn": "$ecsTaskRoleArn",  
  "executionRoleArn": "$ecsTaskExecutionRoleArn",
  "family": "$task_name",
  "requiresCompatibilities": [ 
       "$ECSLaunchType" 
    ],
  "networkMode": "host",
  "cpu": "$ecsTaskCpuUnit",
  "memory": "$ecsTaskMemoryUnit",  
  "containerDefinitions": [
    {
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${root_name}-app",
          "awslogs-region": "$region",
          "awslogs-create-group": "true",
          "awslogs-stream-prefix": "$log_group_name"
        }
      },
      "portMappings": [
EOF
# for port in $ecsTaskPortMapList; do 
# cat <<EOF >> $fout
#         {
#           "hostPort": 3306,
#           "protocol": "tcp",
#           "containerPort": 3306
#         },
#         {
#           "hostPort": 5432,
#           "protocol": "tcp",
#           "containerPort": 5432
#         },
#         {
#           "hostPort": $port,
#           "protocol": "tcp",
#           "containerPort": $port
#         },        
#         {
#           "hostPort": 80,
#           "protocol": "tcp",
#           "containerPort": 80
#         }            
# EOF
# done
cat <<EOF >> $fout
        {
          "hostPort": 443,
          "protocol": "tcp",
          "containerPort": 443
        }        
      ],
      "cpu": 0,
      "environment": [
        {
          "name": "GIT_TOKEN",
          "value": "arn:aws:secretsmanager:${region}:$account:secret:$ssmgittoken"
        }
      ],
      "image": "$aws_ecr_repository_url_app",
      "name": "$app_container_name",
      "essential": true
    }
  ]
}
EOF

## force generate from template
if ${ecsTaskFromTemplate:-false} && [ ! -z $ecsTaskTemplate ] ; then
    envsubst <${ecsTaskTemplate}>$fout
fi

res=$(aws logs describe-log-groups --log-group-name-prefix $log_group_name)
lgempty=$(echo $res | if jq -e 'keys_unsorted as $keys
              | ($keys | length == 1) 
                and .[($keys[0])] == []' > /dev/null; \
                    then echo "yes"; else echo "no"; fi)

if [ lgempty == "yes" ]; then
    aws logs create-log-group \
        --log-group-name $log_group_name \
        --region $region --profile ${profile_name}
fi

#check if cluster exists, if not create it
res=$(aws ecs describe-clusters --clusters ${ecs_cluster_name} \
          --region $region --profile ${profile_name})

if $(echo $res | jq '.clusters | length==0') ; then
    res=$(aws ecs create-cluster \
              --cluster-name ${ecs_cluster_name} \
              --region $region \
              --profile ${profile_name})
    
    echo $res > $logoutputdir/output-create-ecs-cluster.json
fi


if [[ ! -z $ecsExistingTaskName ]]; then
echo "Using existing task with task_name=$ecsExistingTaskName ..."
cat <<EOF > $logoutputdir/output-register-ecs-task.json
{ "taskDefinition": { "taskDefinitionArn": "arn:aws:ecs:${region}:${account}:task-definition/${ecsExistingTaskName}" } }
EOF

else

    #Register the task definition.
    res=$(aws ecs register-task-definition \
              --cli-input-json file://$fout \
              --region $region --profile ${profile_name})
    
    echo $res > $logoutputdir/output-register-ecs-task.json
fi
