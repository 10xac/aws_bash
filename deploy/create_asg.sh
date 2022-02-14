####### Reference
### https://docs.aws.amazon.com/cli/latest/reference/autoscaling/create-auto-scaling-group.html
######

res=$(aws autoscaling describe-auto-scaling-groups \
          --auto-scaling-group-names $AsgName \
          --region $region --profile ${profile_name})

asgexist=$(echo $res | jq -r '.AutoScalingGroups | length>0')

if $asgexist ; then
    echo "updating asg .."    
    res=$(aws autoscaling update-auto-scaling-group \
              --auto-scaling-group-name $AsgName \
              --launch-template LaunchTemplateName=$AsgTemplateName,Version='$Latest' \
              --min-size $AsgMaxSize \
              --max-size $AsgMaxSize \
              --desired-capacity $AsgDesiredSize \
              --region $region --profile ${profile_name})
    echo $res > $logoutputdir/output-update-auto-scaling-group.json    
else
    echo "creating asg .."
    res=$(aws autoscaling create-auto-scaling-group \
              --auto-scaling-group-name $AsgName \
              --launch-template LaunchTemplateName=$AsgTemplateName,Version='$Latest' \
              --target-group-arns $targetGroupArn \
              --health-check-type EC2 \
              --health-check-grace-period 160 \
              --min-size $AsgMaxSize \
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

