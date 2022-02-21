#--------------------------------------------------------#
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
###-------- Certificate setup -----##
##------------------------------------------------------#

#Create the service using the registered task definition and the Application Load Balancer.
fout=$configoutputdir/ecs_service_def.json
envsubst <${ecsServiceTemplate}>$fout

##create service 
res=$(aws ecs create-service --cluster ${ecs_cluster_name} \
    --service-name ${service_name} \
    --cli-input-json file://$fout \
    --region $region --profile ${profile_name})

echo $res > $logoutputdir/output-create-service.json

# aws ecs create-capacity-provider \
#     --name "${service_name}_cp" \
#     --auto-scaling-group-provider autoScalingGroupArn=arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:a1b2c3d4-5678-90ab-cdef-EXAMPLE11111:autoScalingGroupName/MyAutoScalingGroup,managedScaling={status=ENABLED,targetCapacity=100,minimumScalingStepSize=1,maximumScalingStepSize=100},managedTerminationProtection=ENABLED
