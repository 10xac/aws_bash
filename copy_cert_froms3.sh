#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
if [ $# -eq 0 ]; then
    echo "Usage: ecs_deploy <path to params file>"
    exit 0
fi
echo "Loading variables from $1"
source $1 #many key variables returned

if [ -z "$s3bucket" ]; then
    echo "ERROR: s3bucket is empty - you must set it to S3 bucket path!"
fi

mkdir -p ./data/sre-board/certbot
mkdir -p ./data/sre-board/nginx/app

#copy cert
aws s3 cp ${s3bucket}/ssl-certs/sre-board ./data/sre-board/certbot/conf --recursive
aws s3 cp ${s3bucket}/nginx/sre-board ./data/sre-board/nginx/app --recursive 


if [ -d ./cert ]; then
   cp -r ./cert /etc/ssl/letsencrypt
fi
