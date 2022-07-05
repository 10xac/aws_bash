export AWS_PAGER=""

echo "Number passed arguments: $#"
if [ $# -gt 0 ]; then
   source $1
else
    echo "You must pass a configuration file that contains key parameters"
    exit 0
fi

if [ $# -gt 1 ]; then
    action=$2
else
    action="status"
fi

hosted_zone_id=Z034028834IXN0CQEMHZ9

echo "Requested action is: $action"

if [ ! -z $root_name ]; then
    name=$root_name
    TYPE=$AwsInstanceType
fi

if [ -z $profile_name ]; then
    profile_name=$profile
fi

echo "------------------------------------"
echo "                 `date`"
echo "Instance parameters for name=$name; type=$TYPE"
echo "------------------------------------"
echo ""



function update_r53() {

    mkdir -p logs/$1
    fout=logs/$1/r53_record.json

#http://www.scalingbits.com/aws/dnsfailover/changehostnameentries
cat <<EOF > $fout
{
  "Comment": "CREATE/UPDATE a record ",
  "Changes": [{
  "Action": "UPSERT",
              "ResourceRecordSet": {
                  "Name": "$dns_namespace",
                  "Type": "A",
                  "TTL": 60,
              "ResourceRecords": [{ "Value": "$1"}]

              }
  }]
}
EOF

echo "-------------start conf file written------------"
echo "Setting the following Route53 DNS Record:"
cat $fout
echo "-------------end conf file written------------"


#----------------------------------------#
###-------- Create a record set---------##
##---------------------------------------#
res=$(aws route53 change-resource-record-sets \
    --hosted-zone-id ${hosted_zone_id} \
    --change-batch file://$fout \
    --region $region \
    --profile $profile_name)

echo $res > logs/$1/output-route53-change-record-latest.json

}




RequestedFields="{Name:Tags[?Key=='Name']|[0].Value,Id:InstanceId,PublicIP:PublicIpAddress,Status:State.Name}"
InstanceVars=$(aws ec2 describe-instances --region $region \
                   --filters "Name=instance-type,Values=$TYPE" \
                   --filters "Name=tag:team,Values=$team" "Name=tag:Name,Values=$name" \
                   --query "Reservations[*].Instances[*].$RequestedFields" \
                   --profile $profile_name --region $region
            )

echo "Instanced found based on name and team tag filters: "
echo $InstanceVars


# get length of an array
arrayIp=( `echo $InstanceVars | jq -re '.[] | .[] | .PublicIP'` )
arrayId=( `echo $InstanceVars | jq -re '.[] | .[] | .Id'` )
arrayState=( `echo $InstanceVars | jq -re '.[] | .[] | .Status'` ) 


# use for loop to read all values and indexes
arraylength=${#arrayId[@]}
for (( i=0; i<${arraylength}; i++ ));
do
    ip=${arrayIp[$i]}
    state=${arrayState[$i]}
    echo "InstanceId = $ip has InstanceState = $state"
    
    if [ $state = "running" ]; then
        echo "update ip=$ip to record dns=$dns_namespace .."
        update_r53 $ip
    fi

    
done


        #            

