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


#####example to start at 6hr utc and stop at 21hr utc
#0 6 * * * /bin/bash /home/centos/trainees_aws_cluster/start_stop.sh start > /home/centos/cronlog.txt
#0 21 * * * /bin/bash /home/centos/trainees_aws_cluster/start_stop.sh stop > /home/centos/cronlog.txt 

echo "------------------------------------"
echo "                 `date`"
echo "------------------------------------"
echo ""



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
arrayId=( `echo $InstanceVars | jq -re '.[] | .[] | .Id'` )
arrayState=( `echo $InstanceVars | jq -re '.[] | .[] | .Status'` ) 


# use for loop to read all values and indexes
arraylength=${#arrayId[@]}
for (( i=0; i<${arraylength}; i++ ));
do
    id=${arrayId[$i]}
    state=${arrayState[$i]}
    echo "InstanceId = $id has InstanceState = $state"
    
    if [ $action = "start" ]; then
        if [ $state = "stopped" ]; then
            echo "starting instance-id=$id .."
            aws ec2 start-instances --instance-ids $id --profile $profile --region $region
        fi
    fi
    if [ $action = "stop" ]; then
        if [ $state = "running" ]; then
            echo "stopping instance-id=$id .."
            aws ec2 stop-instances --instance-ids $id --profile $profile --region $region
        fi
    fi
    if [ $action = "terminate" ]; then
        if [ $state = "running" ]; then
            echo "terminating instance-id=$id .."
            aws ec2 terminate-instances --instance-ids $id --profile $profile --region $region
        fi
    fi

    
done
