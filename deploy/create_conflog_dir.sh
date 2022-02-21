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

if [ ! -z ${root_name} ]; then
    echo "Running from directory: `pwd`"
    export logoutputdir=output/${root_name}/logs
    export configoutputdir=output/${root_name}/configs
    mkdir -p $logoutputdir
    mkdir -p $configoutputdir
fi
