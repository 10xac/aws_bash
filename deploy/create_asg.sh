####### Reference
### https://docs.aws.amazon.com/cli/latest/reference/autoscaling/create-auto-scaling-group.html
######

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


res=$(aws autoscaling describe-auto-scaling-groups \
          --auto-scaling-group-names $AsgName \
          --region $region --profile ${profile_name})

asgexist=$(echo $res | jq -r '.AutoScalingGroups | length>0')

vpc_identifier=""
for x in $public_subnet1 $public_subnet2 $public_subnet3 $public_subnet4; do
    if [ ! -z $x ]; then
        vpc_identifier="$vpc_identifier,$x"
    fi
done

if $asgexist ; then
    echo "updating asg .."    
    res=$(aws autoscaling update-auto-scaling-group \
              --auto-scaling-group-name $AsgName \
              --launch-template LaunchTemplateName=$AsgTemplateName,Version='$Latest' \
              --min-size $AsgMinSize \
              --max-size $AsgMaxSize \
              --desired-capacity $AsgDesiredSize \
              --region $region --profile ${profile_name})
    echo $res > $logoutputdir/output-update-auto-scaling-group.json    
else
    echo "creating asg .."
    echo "Available subnets for ASG: $vpc_identifier"
    res=$(aws autoscaling create-auto-scaling-group \
              --auto-scaling-group-name $AsgName \
              --launch-template LaunchTemplateName=$AsgTemplateName,Version='$Latest' \
              --vpc-zone-identifier $vpc_identifier \              
              --target-group-arns $targetGroupArn \
              --health-check-type EC2 \
              --health-check-grace-period 60 \
              --min-size $AsgMinSize \
              --max-size $AsgMaxSize \
              --desired-capacity $AsgDesiredSize \
              --termination-policies "OldestInstance" \
              --vpc-zone-identifier "$public_subnet1,$public_subnet2" \
              --region $region --profile ${profile_name})
    echo $res > $logoutputdir/output-create-auto-scaling-group.json        
fi

#update tags
echo "Updating asg tags"
keyval="Key=Name,Value=${root_name}"
describe="ResourceId=${AsgName},ResourceType=auto-scaling-group"
res=$(aws autoscaling create-or-update-tags \
          --tags "$describe,$keyval,PropagateAtLaunch=true" \
          --region $region --profile ${profile_name})          

