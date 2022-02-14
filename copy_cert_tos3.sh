#!/bin/sh

#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
if [ $# -eq 0 ]; then
    echo "Usage: ecs_deploy <path to params file>"
    exit 0
fi
echo "Loading variables from $1"
source $1 #many key variables returned

if [[ "$email" == *"adludio.com" ]]; then
    s3bucket=${s3bucket:-s3://ml-box-data}
fi
if [[ "$email" == *"10academy.org" ]]; then
    s3bucket=${s3bucket:-s3://10ac-team}
fi

s3certpath=${s3bucket}/ssl-certs/${root_name}
cert_path="./data/${root_name}/certbot/conf"

s3nginxpath=${s3bucket}/nginx/${root_name}
nginx_path="./data/sre-board/nginx/app"

#copy cert
if [ -d $cert_path ]; then
    aws s3 cp ${cert_path} $s3certpath --recursive 
fi

#nginx conf
if [ -d $nginx_path ]; then
    aws s3 cp ${nginx_path} $s3nginxpath --recursive 
fi
