if [ -z $setup_ec2 ]; then
    setup_ec2=${setupec2-true}
fi

export ec2LaunchTemplate=template/ec2-launch-template.json

if [ -f $logoutputdir/alb_output_params.sh ]; then
    echo "ALB output file exists  ..."      
    source $logoutputdir/alb_output_params.sh
    if [ -z $loadbalancerArn ] || [ -z $targetGroupArn ]; then
        echo "***Either ALB ARN or Target group ARN is missing."
        export create_and_setup_alb=$setup_ec2
    else
        export create_and_setup_alb=false
    fi
else
    echo "$logoutputdir/alb_output_params.sh does not exist"
    export create_and_setup_alb=$setup_ec2
fi

if [ -f $logoutputdir/clt_output_params.sh ]; then
    echo "Launch template output file exists  ..."
    source $logoutputdir/clt_output_params.sh
    export create_launch_template=false
else
    echo "$logoutputdir/clt_output_params.sh file does not exist"    
    export create_launch_template=$setup_ec2
fi

export create_and_setup_asg=false

# if [ -f $logoutputdir/output-create-auto-scaling-group.json ]; then
#     echo "ASG output file exists  ..."    
#     export create_and_setup_asg=false
# else
#     echo "$logoutputdir/output-create-auto-scaling-group.json does not exist"
#     export create_and_setup_asg=$setup_ec2
# fi

#loadbalance and autoscale
export alb="ecs-${root_name}-alb"
export AsgName="ecs-${root_name}-asg"
export AsgMinSize=1
export AsgMaxSize=1
export AsgDesiredSize=1
export AsgTemplateName="${root_name}-launch-template"
export AsgTemplateVersion=1
