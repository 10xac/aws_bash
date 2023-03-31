set -e

export AWS_PAGER=""

#-------------------------------------------------------------------------
#             process input arguments
#-------------------------------------------------------------------------

echo "Number passed arguments: $#"
if [ $# -gt 0 ]; then
   source $1
else
    echo "You must pass the following"
    echo "     1st argument - a configuration file: that contains key parameters"
    echo "     2nd argument - action: status or iplink  "
    exit 0
fi


if [ -z $profile_name ]; then
    profile_name=$profile
fi

export AWS_DEFAULT_PROFILE=$profile_name
export AWS_DEFAULT_REGION=$region

#-------------------------------------------------------------------------
#             define key variables
#-------------------------------------------------------------------------

name="data"
vpc_name="${name}-vpc"
subnet_name="${name}-subnet"

rootdir=${name}_vpc
logoutputdir="logs/${rootdir}/${profile_name}"

mkdir -p $logoutputdir
outputdir=$(dirname $logoutputdir)

# aws s3 rm ${s3root}/aws_bash_output/${rootdir}/  --recursive --region $region --profile $profile_name
# rm -r ${outputdir}
# mkdir -p $logoutputdir

#echo "sync $outputdir from s3 .."
#aws s3 sync ${s3root}/aws_bash_output/${rootdir}/ ${outputdir}/ \
#    --region $region --profile $profile_name

echo "******Log directory: $logoutputdir**** "




#-------------------------------------------------------------------------
#             create VPC and Subnets 
#-------------------------------------------------------------------------
#create vpc with name tags
fout=$logoutputdir/create_vpc.json
if [ ! -f $fout ]; then
    echo "creating vpc with name=$name ..."
    res=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 \
              --region $region --profile $profile_name)
    export vpc_id=$(echo $res | jq -r '.Vpc.VpcId')
    echo "vpc_id=${vpc_id}"
    
    #save cli output to file    
    echo $res > $fout
    
    aws ec2 create-tags --resources ${vpc_id} \
        --tags Key=Name,Value="${name}-vpc" \        
        --region $region --profile $profile_name
    

    echo "... done with creating vpc!"
else
    echo "reading vpc_id from log .."
    export vpc_id=$(cat $fout | jq -r '.Vpc.VpcId')
    echo "vpc_id=${vpc_id}"
fi


#create private and public subnets
privateids=()
publicids=()
for l in A B; do
    echo "creating private-$l and public-$l subnets ..."
    #create public subnets with name tags    
    if [ $l == "A" ]; then
        i=1
    else
        i=3
    fi

    fout=$logoutputdir/public_subnet_$l.json        
    if [ ! -f $fout ]; then    
        res=$(aws ec2 create-subnet --vpc-id ${vpc_id} --cidr-block 10.0.$i.0/24 \
                  --region $region --profile $profile_name)
        export public_subnetid=$(echo $res | jq -r '.Subnet.SubnetId')
        echo "public_subnetid=${public_subnetid}"        
        publicids+=("${public_subnetid}")

        #save cli output to file
        echo $res > $fout

        aws ec2 create-tags --resources ${public_subnetid} \
            --tags Key=Name,Value=${name}-private-$l \
            --region $region --profile $profile_name
        

    else
        echo "reading public subnetid from log .."
        export public_subnetid=$(cat $fout | jq -r '.Subnet.SubnetId')
        echo "public_subnetid=${public_subnetid}"
        publicids+=("${public_subnetid}")         
    fi
    
    #create private subnets with name tags
    if [ $l == "A" ]; then
        i=2
    else
        i=4
    fi

    fout=$logoutputdir/private_subnet_$l.json
    if [ ! -f $fout ]; then        
        res=$(aws ec2 create-subnet --vpc-id ${vpc_id} --cidr-block 10.0.$i.0/24 \
                  --region $region --profile $profile_name)
        export private_subnetid=$(echo $res | jq -r '.Subnet.SubnetId')
        echo "private_subnetid=${private_subnetid}"
        privateids+=("${private_subnetid}")

        #save cli output to file
        echo $res > $fout

        aws ec2 create-tags --resources ${private_subnetid} \
            --tags Key=Name,Value=${name}-private-$l \
            --region $region --profile $profile_name
        
    else
        echo "reading private subnetid from log .."
        export private_subnetid=$(cat $fout | jq -r '.Subnet.SubnetId')
        echo "private_subnetid=${private_subnetid}"
        privateids+=("${private_subnetid}")                
    fi

    echo "... done with creating subnets!"
done
#
subnetids=(${privateids[@]} ${publicids[@]})


#-------------------------------------------------------------------------
#             create Internet & NAT Gateway 
#-------------------------------------------------------------------------
#create and attach Internet gateway (IGW) - to connect a VPC to the internet

fout=$logoutputdir/create_internet_gateway.json
if [ ! -f $fout ]; then
    echo "creating internet gateway ..."
    res=$(aws ec2 create-internet-gateway \
              --region $region --profile $profile_name)
    export igid=$(echo $res | jq -r '.InternetGateway.InternetGatewayId')
    echo "igid=$igid"
    
    #save cli output to file    
    echo $res > $fout

    aws ec2 create-tags --resources ${igid} \
        --tags Key=Name,Value=${name}-ig \
        --region $region --profile $profile_name
    

    aws ec2 attach-internet-gateway --internet-gateway-id $igid --vpc-id ${vpc_id} \
        --region $region --profile $profile_name
    
    echo "... done with creating internet gateway!"
else
    echo "reading igid from log ..."
    export igid=$(cat $fout | jq -r '.InternetGateway.InternetGatewayId')
    echo "igid=$igid"    
fi


#create elastic public ip that we will use for NAT gateway
fout=$logoutputdir/create_nat_ip.json
if [ ! -f $fout ]; then
    echo "creating nat publicip ..."
    res=$(aws ec2 allocate-address --domain vpc --region $region --profile $profile_name)
    export ipid=$(echo $res | jq -r '.AllocationId')
    echo "ipid=$ipid"
    
    #save cli output to file    
    echo $res > $fout
    
    echo "... done with creating nat publicip!"
else
    echo "reading ipid from log ..."
    export ipid=$(cat $fout | jq -r '.AllocationId')
    echo "ipid=$ipid"
fi


#create a NAT gateway - to enable instances in a private subnet
#    to connect to the internet or other AWS services but not the other way
fout=$logoutputdir/create_nat_gateway.json
if [ ! -f $fout ]; then
    echo "creating nat gateway ..."    
    res=$(aws ec2 create-nat-gateway --subnet-id "${public_subnetid}" --allocation-id $ipid \
              --region $region --profile $profile_name)
    export natid=$(echo $res | jq -r '.NatGateway.NatGatewayId')
    echo "natid=$natid"
    
    #save cli output to file    
    echo $res > $fout

    aws ec2 create-tags --resources ${natid} \
        --tags Key=Name,Value="${name}-nat" \
        --region $region --profile $profile_name

        
    echo "... done with creating nat gateway!"    
else
    echo "reading natid from log ..."
    export natid=$(cat $fout | jq -r '.NatGateway.NatGatewayId')
    echo "natid=$natid"
fi


#-------------------------------------------------------------------------
#------------Create and associate route table for each subnet
#    A route table contains a set of rules that is  used to determine
#    where the network traffic from the subnets or internet gateway will be directed.
#-------------------------------------------------------------------------
for rtname in public private; do
    fout=$logoutputdir/create_${rtname}_route_table.json
    if [ ! -f $fout ]; then
        echo "creating $rtname route table .."
        #Create route table
        res=$(aws ec2 create-route-table --vpc-id ${vpc_id} \
                  --region $region --profile $profile_name)
        export rtid=$(echo $res | jq -r '.RouteTable.RouteTableId')
        echo "rtid=$rtid"
        
        #save cli output to file        
        echo $res > $fout

        aws ec2 create-tags --resources ${rtid} \
            --tags Key=Name,Value="${name}-rt-${rtname}" \
            --region $region --profile $profile_name

    
        echo "... done with $rtname creating route table!"
        
        #Create routes
        echo "creating $rtname route ..."
        res=$(aws ec2 create-route --route-table-id ${rtid} \
            --destination-cidr-block 0.0.0.0/0 \
            --gateway-id $igid \
            --region $region --profile $profile_name)
        
        echo "... done with creating $rtname routes!"
        
        #Associate route table to subnet
        if [ $rtname == "public" ]; then
            arr=( "${publicids[@]}" ) 
        else
            arr=( "${privateids[@]}" ) 
        fi
        
        for subnetid in "${arr[@]}"; do
            echo "associating route table with ${rtname} subnetid=$subnetid .."
            aws ec2 associate-route-table --route-table-id ${rtid} --subnet-id $subnetid \
                --region $region --profile $profile_name
            echo "... done with associating route table with subnet"
        done
    
    
    else
        echo "reading ${rtname} rtid from log ..."
        export rtid=$(cat $fout | jq -r '.RouteTable.RouteTableId')
        echo "rtid=$rtid"        
    fi
done



#-------------------------------------------------------------------------
#             create security groups
#-------------------------------------------------------------------------
#Create a security group for the VPC
fout=$logoutputdir/create_ssh_security_group.json
if [ ! -f $fout ]; then
    echo "creating ssh only security group ..."
    res=$(aws ec2 create-security-group --group-name "allow-only-ssh" \
              --description "allow ssh" --vpc-id ${vpc_id} \
              --region $region --profile $profile_name)
    export sgid=$(echo $res | jq -r '.GroupId')
    echo "sgid=$sgid"
    
    #save cli output to file    
    echo $res > $fout    

    # aws ec2 create-tags --resources ${sgid} \
    #     --tags Key=Name,Value="sg-ssh-only" \        
    #     --region $region --profile $profile_name
    

    aws ec2 authorize-security-group-ingress --group-id $sgid \
        --protocol tcp --port 22 --cidr 0.0.0.0/0 \
        --region $region --profile $profile_name
    echo "... done with creating ssh only security group!"
else
    echo "reading ssh sgid from log ..."
    export sgid=$(cat $fout | jq -r '.GroupId')
    echo "sgid=$sgid"
fi

#-------------------------------------------------------------------------
#             create ssh key pair 
#-------------------------------------------------------------------------
#create ssh key pair
if [ -z $KEY ]; then
    keyname=${KEY}.pem
else
    keyname=${profile_name}_aws_private_key.pem
fi
keyfile=~/.ssh/$keyname

fout=$logoutputdir/create_key_pair.json
if [ ! -f $fout ]; then
    echo "creating ssh key pair ..."
    res=$(aws ec2 create-key-pair --key-name cli-keyPair \
              --query 'KeyMaterial' --output text \
              --region $region --profile $profile_name > $keyfile)

    #save cli output to file    
    echo $res > $fout
    
    chmod 400 $keyfile
    
    echo "... done with creating ssh key pair. Downloaded private key: $keyfile"
else
    echo "key pay $kefile already exists!"
fi

#-------------------------------------------------------------------------
#             sync logfile to s3
#-------------------------------------------------------------------------
echo "sync $outputdir to s3 ..."
aws s3 sync ${outputdir}/ ${s3root}/aws_bash_output/${rootdir}/ \
    --region $region --profile $profile_name


echo "done!"

#    


#Ref
#1.  https://dev.to/mariehposa/how-to-create-vpc-subnets-route-tables-security-groups-and-instances-using-aws-cli-14a4
