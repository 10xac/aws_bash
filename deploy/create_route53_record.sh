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
###-------- Get the id of the hosted zone-------##
##------------------------------------------------------#

host_zone_id=$(aws route53 list-hosted-zones-by-name --dns-name $rootdns | jq '.HostedZones| .[] | . | .Id' | xargs basename)
echo "Extracted hosted_zone_id for $rootdns is: $HOSTZONEID"
HOSTZONEID=${HOSTZONEID:-$host_zone_id}
echo "Using host_zone_id=$HOSTZONEID"


#--------------------------------------------------------#
###-------- Determine what type of record to set -------##
##------------------------------------------------------#

iprecord=false
elbdnsalias=false
if [ ! -z $loadbalancerArn ]; then 
    echo "Load balancer found. setting R53 record alias.."

    res=$(aws elbv2 describe-load-balancers \
              --names $alb \
              --region $region \
              --profile $profile_name
       )

    DNSName=$(echo $res | jq -r ".LoadBalancers[0].DNSName")
    ELBHZNID=$(echo $res | jq -r '.LoadBalancers[0].CanonicalHostedZoneId')

    echo "------------------"
    echo "Adding ELB DNSName=$DNSName, ELBHZNID=$ELBHZNID"
    echo "------------------"
    
    if [ ! -z $DNSName ] && [ ! -z $ELBHZNID ]; then
        elbdnsalias=true
    else
        echo "Output of describe-load-baralncers on alb=$alb"
        #echo $res
        exit 0
    fi
    
else
    echo "No Load balancer found - attempting to fetch instance public ip .."
    #--------------------------------------------------------#
    ###-------- Get the EC2 instance Id from its Name-----##
    ##------------------------------------------------------#
    if [ ! -z $instanceid ]; then
        query='Reservations[].Instances[].[InstanceId,InstanceType,PublicIpAddress,Tags[?Key==`Name`]| [0].Value]'
        instanceid=$(aws ec2 describe-instances \
                         --query $query \
                         --output json \
                         --region $region \
                         --profile $profile_name \
                         | jq '.[] | select(.[3] == (env.root_name)) | .[0]')
        instanceid=$(eval echo $instanceid)
    fi
    
    #------------------------------------------------------------------------------#
    ###-------- Get the public IP of the instance to assign it to a record set----##
    ##----------------------------------------------------------------------------#
    
    export public_ip=$(aws ec2 describe-instances \
                           --instance-ids $instanceid \
                           --query 'Reservations[*].Instances[*].PublicIpAddress' \ 
                           --output text \
                           --region $region \
                           --profile $profile_name                                
                           )
    if [ ! -z $public_id ]; then 
        iprecord=true
    fi
    
fi

if $iprecord || ! $elbdnsalias ; then
    echo "Nither ALB DNS or Instance ID found. Please check the inputs"
    exit 0
fi

#echo "------------done getting relevant variables---------"

#--------------------------------------------------------#
###-------- Get the id of the hosted zone-------##
##------------------------------------------------------#

# rootdns=${rootdns:-$(echo "$dns_namespace" | cut -d "." -f 2,3)}
# res=$(aws route53 list-hosted-zones-by-name \
#                      --dns-name $rootdns \
#                      --region $region \
#                      --profile $profile_name
#    )


# hosted_zone_id= #$(echo $res | jq '.HostedZones| .[] | . | select(.Name == env.hosted_zone) .Id')

# if [ ! -z $$hosted_zone_id ]; then
#     echo "$rootdns hosted_zone_id=$hosted_zone_id"
# else
#     echo "Route 53 hosted zone id for $rootdns not found: "
#     echo $res
# fi

#--------------------------------------------------------#
###-------- create template -------##
##------------------------------------------------------#
#create file
fout=$configoutputdir//r53_record.json

cat <<EOF > $fout
{
  "Comment": "CREATE a record ",
  "Changes": [{
  "Action": "CREATE",
              "ResourceRecordSet": {
                  "Name": "$dns_namespace",
                  "Type": "A",
                  "TTL": 300,
EOF

if $elbdnsalias; then
    
cat <<EOF >> $fout
        "AliasTarget": {
          "HostedZoneId": "${HOSTZONEID}",
          "DNSName": "$DNSName",
          "EvaluateTargetHealth": false
        }
    
EOF

elif $iprecord; then
    
cat <<EOF >> $fout
       "ResourceRecords": [{ "Value": "$public_ip"}]
EOF

fi

#
cat <<EOF >> $fout
              }
  }]
}
EOF

echo "-------------start conf file written------------"
echo "Setting the following Route53 DNS Record:"
cat $fout
echo "-------------end conf file written------------"

if [ -z $HOSTZONEID ]; then
    echo "HOSTZONEID is empty - can't create a record!"
fi

#----------------------------------------#
###-------- Create a record set---------##
##---------------------------------------#
res=$(aws route53 change-resource-record-sets \
    --hosted-zone-id $ELBHZNID \
    --change-batch file://$fout \
    --region $region \
    --profile $profile_name)

echo $res > $logoutputdir/output-route53-change-record-latest.json
