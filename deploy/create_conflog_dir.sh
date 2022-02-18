
if [ ! -z "$1" ]; then
    root_name=$1
else
    echo "Need to pass root_name to create Log and Config Directories"
    exit 1
fi

echo "Running from directory: `pwd`"
export logoutputdir=output/${root_name}/logs
export configoutputdir=output/${root_name}/configs
mkdir -p $logoutputdir
mkdir -p $configoutputdir
