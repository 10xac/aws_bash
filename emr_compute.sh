#Reference
#https://bytes.babbel.com/en/articles/2017-07-04-spark-with-jupyter-inside-vpc.html
#https://cloud-gc.readthedocs.io/en/latest/chapter03_advanced-tutorial/advanced-awscli.html

export AWS_PAGER=""

echo "Number passed arguments: $#"
if [ $# -gt 0 ]; then
   source $1
else
    echo "You must pass a configuration file that contains key parameters"
    exit 0
fi

fname="instance_user_data/${name}_user_data.sh"

echo "sed replacing config file and writing: emr_user_data.sh ->  $fname"
if [[ "$OSTYPE" == "darwin"* ]]; then
    SEDOPTION="-i ''"
else
    SEDOPTION="-i "
fi
sed 's|specfile=.*|specfile='"$udcfile"'|g' user_data.sh > $fname
sed  $SEDOPTION "s|pub_key_basename=|pub_key_basename="${iam_users}"_authorized_keys|g" $fname

s3root=${s3root:-"s3://ml-box-data"}
LOG_URI="${s3root}/emr-cluster-logs/"

echo "using s3root:  $s3root"
echo "log_uri: $LOG_URI"

if [ $service == "emr" ]; then
    
    #user data / bootstrap file

    fpath="${s3root}/emr-bootscripts/$fname"


    echo "Creating EMR cluster with $fname bootstrap file.."
    echo "copy ti path=$fpath"
    aws s3 cp $fname $fpath --profile $profile

    #reference
    #https://docs.aws.amazon.com/cli/latest/reference/emr/create-cluster.html    
    aws emr create-cluster --name $name \
        --release-label emr-6.2.0 \
        --ebs-root-volume-size ${EBS_SIZE} \
        --ec2-attributes \
        KeyName=$KEY,SubnetId=$subnetId \
        --use-default-roles \
        --applications Name=Spark \
        --log-uri ${LOG_URI} \
        --tag name=$name team=$team \
        --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=${TYPE} \
        --bootstrap-actions Name=$fname,Path=$fpath \
        --region $region \
        --profile $profile
    
else
    echo "service is not set to EMR in the config file .. doing nothing"    
fi


if [ $service == "emr-steps" ]; then
    
    #user data / bootstrap file
    fpath="s3://ml-box-data/emr_steps/$fname"
    
    echo "Creating EMR cluster with $fname bootstrap file.."
    echo "copy ti path=$fpath"

    aws s3 cp $fname $fpath --profile $profile

    #reference
    #https://docs.aws.amazon.com/cli/latest/reference/emr/create-cluster.html    
    aws emr create-cluster --name $name \
        --release-label emr-6.2.0 \
        --ebs-root-volume-size 60 \
        --ec2-attributes \
        KeyName=$KEY,SubnetId="subnet-ff24ffb7" \
        --use-default-roles \
        --applications Name=Spark \
        --log-uri 's3://ml-box-data/emr-cluster-logs/' \
        --tag name=$name team=$team \
        --instance-groups InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m5.4xlarge \
        --bootstrap-actions Name=$fname,Path=$fpath \
        --region eu-west-1 \
        --region $region \
        --profile $profile \
        --steps Type=CUSTOM_JAR,Name="Bash Program",Jar="command-runner.jar",ActionOnFailure="TERMINATE_CLUSTER",Args=['bash','-c',"aws s3 cp s3://ml-box-data/airflow/dags/dag_scripts/special_scripts/steps.sh steps.sh;chmod a+rwx steps.sh; bash steps.sh"] \
        --auto-terminate

    
else
    echo "service is not set to EMR in the config file .. doing nothing"    
fi

#InstanceGroupType=CORE,InstanceCount=1,InstanceType=m4.large

# c5d.large
# m4.large
# m5.xlarge
# SubnetId="subnet-ff24ffb7"
# SubnetId="subnet-26a2027c"

#InstanceGroupType=CORE,InstanceCount=1,InstanceType=m5.xlarge \

