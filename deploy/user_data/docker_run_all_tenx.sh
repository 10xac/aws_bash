if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<EOF >>  $fout


aws ecr get-login-password \
    --region ${region} \
| docker login \
    --username AWS \
    --password-stdin 070096167435.dkr.ecr.${region}.amazonaws.com

image1="070096167435.dkr.ecr.us-east-1.amazonaws.com/prod-u2j-cms:latest"
image2="070096167435.dkr.ecr.us-east-1.amazonaws.com/prod-u2j-cms:latest"
docker pull $image1 
docker pull $image2 

dns1="u2jcms.10academy.org"
dns2="u2jcms.10academy.org"


dockerenv1="-p 13q-env REDIRECT_URL=https://${dns_namespace} --env EMAIL_SENDER=${emailsender} --env DATABASE_NAME=${dbname} --env DATABASE_HOST=u2jdb.cluster-crlafpfc5g5y.us-east-1.rds.amazonaws.com -v /mnt/all-tenx-system/src-${src_public_suffix}:/opt/app/src -v /mnt/all-tenx-system/public-${src_public_suffix}:/opt/app/public --env appkey=$appkey --env appkeysalt=$appkeysalt --env APP_KEYS=${appkey},${appkeysalt} --env API_TOKEN_SALT=$appkeysalt --env ADMIN_JWT_SECRET=$appkey"

dockerenv2="-p 1337:1337 --env REDIRECT_URL=https://${dns_namespace} --env EMAIL_SENDER=${emailsender} --env DATABASE_NAME=${dbname} --env DATABASE_HOST=u2jdb.cluster-crlafpfc5g5y.us-east-1.rds.amazonaws.com -v /mnt/all-tenx-system/src-${src_public_suffix}:/opt/app/src -v /mnt/all-tenx-system/public-${src_public_suffix}:/opt/app/public --env appkey=$appkey --env appkeysalt=$appkeysalt --env APP_KEYS=${appkey},${appkeysalt} --env API_TOKEN_SALT=$appkeysalt --env ADMIN_JWT_SECRET=$appkey"


docker run $dockerenv1 -d $image1
docker run $dockerenv2 -d $image2

EOF
