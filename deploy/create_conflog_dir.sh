#--------------------------------------------------------#
###-----Define necessary environment variables if passed -----##
##------------------------------------------------------#
if [ ! -z "$1" ]; then
    echo "ConfLogDirs: setting root_name=$1. Note directories are created relative to pwd=`pwd`"
    root_name=$1 #many key variables returned
    ENV=${2:-"prod"}
    profile_name=${3:-tenac}
    region=${4:-eu-west-1}
fi

if [ ! -z ${root_name} ]; then
    base_dir=$root_name
    #
    export logoutputdir=output/${base_dir}/logs
    export configoutputdir=output/${base_dir}/configs

    #
    aws s3 cp $s3bucket/aws_bash_output/${base_dir} output/ --recursive \
        --region $region --profile $profile_name

    if [ ! -d $logoutputdir ]; then
        echo "ConfLogDirs: creating $logoutputdir directory"
        mkdir -p $logoutputdir                
    else
        echo "ConfLogDirs: $logoutputdir exist"
    fi

    if [ ! -d $confoutputdir ]; then
        echo "ConfLogDirs: creating $configoutputdir directory"
        mkdir -p $configoutputdir                
    else
        echo "ConfLogDirs: $configoutputdir exist"
    fi
    


fi
