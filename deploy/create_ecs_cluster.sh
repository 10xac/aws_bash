##------------------------------------------------------#
###-----Define necessary environment variables if passed -----##
##------------------------------------------------------#
if [ $# -gt 0 ]; then
    echo "Loading variables from $1"
    source $1 #many key variables returned
    source create_conflog_dir.sh $root_name
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
envsubst <${ecsTaskTemplate}>$fout

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
    aws ecs create-cluster --cluster-name ${ecs_cluster_name} \
        --region $region --profile ${profile_name}
fi


#Register the task definition.
aws ecs register-task-definition \
    --cli-input-json file://$fout \
    --region $region --profile ${profile_name}


