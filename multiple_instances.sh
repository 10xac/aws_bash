curdir=`pwd`


#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
if [ $# -lt 2 ]; then
    echo "Usage: bash multiple_instance.sh <path to params file> <action type 'create' or 'iplink'> [[key=value]]"
    exit 0
fi

paramsfile=$1; shift
action=$1; shift
echo "Using paramsfile=$paramsfile for action=$action .."

#--- parse named arguments key=value
for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

istart=${istart:-1}
iend=${iend:-5}
echo "number of instances to create: $istart to $iend"

ec2script=${ec2script:-"ec2_compute.sh"}
ipscript=${ipscript:-"postup/update_r53_record.sh"}


#--------------------------------------------------------#
###--------execute the scripts with input arguments------#
##-------------------------------------------------------#
for ((ig=$istart; ig<=$iend; ig++)); do

    if [ "$action" == "create" ]; then
        echo "******creating instances for group=$ig********"
        group=$ig bash $ec2script $paramsfile 
    elif [ "$action" == "iplink" ]; then
        echo "*********updating r53 record with IP for group=$ig******"        
        group=$ig bash $ipscript $paramsfile
    else
        echo "*****unknown operation requested 1st argument=$1*****"
    fi

done
