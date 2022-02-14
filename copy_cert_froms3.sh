#--------------------------------------------------------#
###--------Define necessary environment variables-----##
##------------------------------------------------------#
if [ $# -eq 0 ]; then
    echo "Usage: ecs_deploy <path to params file>"
    exit 0
fi
echo "Loading variables from $1"
source $1 #many key variables returned


mkdir -p ./data/sre-board/certbot
mkdir -p ./data/sre-board/nginx/app

#copy cert
if [[ "$email" == *"adludio.com" ]]; then
    s3bucket=${s3bucket:-s3://ml-box-data}
fi
if [[ "$email" == *"10academy.org" ]]; then
    s3bucket=${s3bucket:-s3://10ac-team}
fi

aws s3 cp ${s3bucket}/ssl-certs/sre-board ./data/sre-board/certbot/conf --recursive
aws s3 cp ${s3bucket}/nginx/sre-board ./data/sre-board/nginx/app --recursive 


if [ -d ./cert ]; then
   cp -r ./cert /etc/ssl/letsencrypt
fi
