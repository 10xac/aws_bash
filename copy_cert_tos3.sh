#!/bin/sh

curdir=`pwd`

#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
if [ $# -eq 0 ]; then
    echo "Usage: ecs_deploy <path to params file>"
    exit 0
fi
echo "Loading variables from $1"
source $1 #many key variables returned

cd $curdir

if [ -z "$s3bucket" ]; then
    echo "ERROR: s3bucket is empty - you must set it to S3 bucket path!"
fi


s3certpath=${s3bucket}/ssl-certs/${root_name}
cert_path="./data/${root_name}/certbot/conf"

s3nginxpath=${s3bucket}/nginx/${root_name}
nginx_path="./data/{root_name}/nginx/app"

#copy cert
if [ -d $cert_path ]; then
    aws s3 cp ${cert_path} $s3certpath --recursive 
fi

#nginx conf
if [ -d $nginx_path ]; then
    aws s3 cp ${nginx_path} $s3nginxpath --recursive 
fi
