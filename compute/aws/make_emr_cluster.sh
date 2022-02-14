#Reference
#https://bytes.babbel.com/en/articles/2017-07-04-spark-with-jupyter-inside-vpc.html

if [ $# -gt 0 ]; then
    name=$1
else
    name="dsjhub2"
fi

if [ $# -gt 1 ]; then
    fname=$2
else
    fname='emr_bootstrap.sh'
fi

fpath="s3://ml-box-data/emr_cluster_setup/$fname"

echo "name=$fname"
echo "path=$fpath"
aws s3 cp $fname $fpath --profile adludio


aws emr create-cluster --name $name \
    --release-label emr-6.2.0 \
    --ebs-root-volume-size 60 \
    --ec2-attributes \
    KeyName="ml-box",SubnetId="subnet-ff24ffb7" \
    --use-default-roles \
    --log-uri 's3://aws-logs-489880714178-eu-west-1/elasticmapreduce/' \
    --applications Name=Hive Name=Spark Name=Pig Name=Hue \
    --tag name=$name team=datascience \
    --instance-groups \
    InstanceGroupType=MASTER,InstanceCount=1,InstanceType=m5.4xlarge \
    --bootstrap-actions Name=$fname,Path=$fpath \
    --region eu-west-1 \
    --profile adludio



#https://docs.aws.amazon.com/cli/latest/reference/emr/create-cluster.html
    # InstanceProfile="EMR_EC2_DefaultRole",
    # --service-role "EMR_DefaultRole" \
    # --auto-scaling-role "EMR_AutoScaling_DefaultRole" \

#BidPrice=0.1,
#    InstanceGroupType=CORE,InstanceCount=0,InstanceType=m5.xlarge \    
