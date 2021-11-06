#--------------------------------------------------------#
###-------- Create cluster and task definition -----##
##------------------------------------------------------#
set -e

mkdir -p output/ecs

#Create a task definition with both the container definitions.
#Substitute the environment variables, create a log group, an ECS cluster, and register the task definition.
envsubst <template/ecs_task_def.template>ecs_task_def.json

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

aws ecs create-cluster --cluster-name $cluster \
    --region $region --profile ${profile_name}


#Register the task definition.
aws ecs register-task-definition \
    --cli-input-json file://ecs_task_def.json \
    --region $region --profile ${profile_name}


mv ecs_task_def.* output/ecs/
