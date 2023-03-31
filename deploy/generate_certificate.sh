##------------------------------------------------------#
###-----Define necessary environment variables if passed -----##
##------------------------------------------------------#
if [ $# -gt 1 ]; then
    echo "Loading variables from $1"
    source $1 #many key variables returned
    source $2
    source create_conflog_dir.sh ""
    echo "confdir=$configoutputdir"
    echo "logdir=$logoutputdir"    
else
    echo "Usage: ecs_deploy <path to deployment params file> <path to instance params file> "
    exit 0
fi


##------------------------------------------------------#
###-----Create an EC2 Instance -----##
##------------------------------------------------------#

echo "Creating and launching the EC2 Instance  ..."  
   
source ec2_compute.sh  
instanceid=$(eval echo $instance_id)
echo $instanceid

sleep 2m

export public_ip=$(aws ec2 describe-instances --instance-ids $instanceid --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

envsubst <deploy/template/record_set_template.template > deploy/output/record_set_template.json


#----------------------------------------#
###-------- Create a record set---------##
##---------------------------------------#
aws route53 change-resource-record-sets --hosted-zone-id Z2WWUT59YJNDH2 --change-batch file://deploy/output/record_set_template.json

sleep 1m

#------------------------------------------------#
###-------- Allow ssm for the created instance--##
##-----------------------------------------------#

association_id=$(aws ec2 describe-iam-instance-profile-associations --filters Name=instance-id,Values=${instanceid} --query IamInstanceProfileAssociations[0].AssociationId --output text)
echo $association_id

aws ec2 replace-iam-instance-profile-association --iam-instance-profile Name=AmazonSSMInstanceProfileForInstances     --association-id $association_id

sleep 12m

#----------------------------------------#
###-------- Create Config file---------##
##---------------------------------------#
aws ssm send-command --document-name "AWS-RunPowerShellScript" --instance-ids $instanceid --parameters commands="echo export dns_namespace=${dns_namespace} > /home/ec2-user/aws_bash/deploy/config/config.sh"

aws ssm send-command --document-name "AWS-RunPowerShellScript" --instance-ids $instanceid --parameters commands="echo export email=${email} >> /home/ec2-user/aws_bash/deploy/config/config.sh"

aws ssm send-command --document-name "AWS-RunPowerShellScript" --instance-ids $instanceid --parameters commands="chmod -R 755 /home/ec2-user/"

sleep 1m

#----------------------------------------#
###-------- Run generator script---------##
##---------------------------------------#

aws ssm send-command --document-name "AWS-RunPowerShellScript" --instance-ids $instanceid --parameters commands="bash gen-letsencrypt-cert.sh deploy/configs/config.sh"

