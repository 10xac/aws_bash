#--------------------------------------------------------#
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
###-------- Create the Application Load Balancer -----##
##------------------------------------------------------#
if [ -z $loadbalancerArn ]; then
    res=$(aws elbv2 create-load-balancer --name $alb \
              --scheme internet-facing \
              --subnets $public_subnet1 $public_subnet2 \
              --security-groups $sg --region $region --profile ${profile_name})
    
    export loadbalancerArn=$(echo $res | jq -r '.LoadBalancers[0].LoadBalancerArn')
fi

if [ -z $targetGroupArn ]; then
    res=$(aws elbv2 create-target-group \
              --name ecs-${root_name}-https-target \
              --protocol HTTPS \
              --port 443 \
              --health-check-protocol HTTP \
              --health-check-port 80 \
              --health-check-timeout-seconds 5 \
              --health-check-interval-seconds 60 \
              --health-check-path / \
              --target-type instance \
              --vpc-id $vpcId \
              --region $region --profile ${profile_name})
    
    export targetGroupArn=$(echo $res | jq -r '.TargetGroups[0].TargetGroupArn')
fi

echo "--------------ALB setup finished-----------"
echo "loadbalancerArn=$loadbalancerArn"
echo "targetGroupArn=$targetGroupArn"
echo "-----------------------------------------------------"

echo "export loadbalancerArn=$loadbalancerArn" > $logoutputdir/alb_output_params.sh
echo "export targetGroupArn=$targetGroupArn" > $logoutputdir/alb_output_params.sh

aws elbv2 create-listener --load-balancer-arn $loadbalancerArn \
    --protocol HTTPS --port 443  \
    --certificates CertificateArn=$certificateArn \
    --default-actions Type=forward,TargetGroupArn=$targetGroupArn \
    --region $region --profile ${profile_name}

