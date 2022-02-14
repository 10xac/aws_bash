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

echo "Requested action is: $action"


echo "------------------------------------"
echo "                 `date`"
echo "------------------------------------"
echo ""


# InstanceIds=$(aws ec2 describe-instances \
#                   --filters "Name=instance-type,Values=$TYPE" \
#                   --filters "Name=tag:team,Values=$team" \
#                   --query "Reservations[].Instances[].InstanceId")

RequestedFields="{Name:Tags[?Key=='Name']|[0].Value,Id:InstanceId,PublicIP:PublicIpAddress,Status:State.Name}"
InstanceVars=$(aws ec2 describe-instances --region $region \
                   --filters "Name=instance-type,Values=$TYPE" \
                   --filters "Name=tag:team,Values=$team" "Name=tag:Name,Values=$name" \
                   --query "Reservations[*].Instances[*].$RequestedFields" \
                   --profile $profile                   
            )

echo "Instanced found based on name and team tag filters: "
echo $InstanceVars
echo 

# get length of an array
arrayName=( `echo $InstanceVars | jq -re '.[] | .[] | .Name'` )
arrayId=( `echo $InstanceVars | jq -re '.[] | .[] | .Id'` )
arrayState=( `echo $InstanceVars | jq -re '.[] | .[] | .Status'` ) 
arrayIp=( `echo $InstanceVars | jq -re '.[] | .[] | .PublicIp'` )

# # use for loop to read all values and indexes
# arraylength=${#arrayId[@]}
# for (( i=0; i<${arraylength}; i++ ));
# do
#     name=${arrayName[$i]}
#     id=${arrayId[$i]}
#     ip=${arrayIp[$i]}
#     state=${arrayState[$i]}
    
#     echo "InstanceName=$name; InstanceId = $id; State = $state; PublicIp = $ip"
    
# done
