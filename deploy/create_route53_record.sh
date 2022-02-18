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
###-------- Get the id of the hosted zone-------##
##------------------------------------------------------#

hosted_zone_id=$(aws route53 list-hosted-zones \
                     | jq '.HostedZones| .[] | . | select(.Name == env.hosted_zone) .Id')
echo hosted_zone_id=$hosted_zone_id

#--------------------------------------------------------#
###-------- Get the EC2 instance Id from its Name-----##
##------------------------------------------------------#
query='Reservations[].Instances[].[InstanceId,InstanceType,PublicIpAddress,Tags[?Key==`Name`]| [0].Value]'
instanceid=$(aws ec2 describe-instances \
                 --query $query \
                 --output json \
                 | jq '.[] | select(.[3] == (env.root_name)) | .[0]')
instanceid=$(eval echo $instanceid)

#------------------------------------------------------------------------------#
###-------- Get the public IP of the instance to assign it to a record set----##
##----------------------------------------------------------------------------#

export public_ip=$(aws ec2 describe-instances \
                       --instance-ids $instanceid \
                       --query 'Reservations[*].Instances[*].PublicIpAddress' \
                       --output text)

#create file
fout=$logoutputdir//r53_record.json
envsubst <${route53RecordTemplate}>$fout


#----------------------------------------#
###-------- Create a record set---------##
##---------------------------------------#
aws route53 change-resource-record-sets \
    --hosted-zone-id Z2WWUT59YJNDH2 \
    --change-batch file://$fout

