if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<'EOF' >>  $fout
#!/bin/bash


# AWS ECR Login
region="us-east-1"
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin 070096167435.dkr.ecr.${region}.amazonaws.com

# Define Docker images
apply_cms_image="070096167435.dkr.ecr.us-east-1.amazonaws.com/prod-apply-cms"
apply_tenx_image="070096167435.dkr.ecr.us-east-1.amazonaws.com/dev-tenx-apply"
cms_image="070096167435.dkr.ecr.us-east-1.amazonaws.com/prod-u2j-cms"
tenx_image="070096167435.dkr.ecr.us-east-1.amazonaws.com/prod-u2j-tenx"

# Pull Docker images
docker pull $apply_cms_image
docker pull $apply_tenx_image
docker pull $cms_image
docker pull $tenx_image

# DNS and Database variables
dns1="pai-apply-cms.10academy.org"
dns2="pai-apply.10academy.org"
dns3="pai-cms.10academy.org"
dns4="pai.10academy.org"

port1="1337"
port2="5173"
port3="5000"
port4="3000"

port11="1337"
port22="5173"
port33="1337"
port44="3000"

dbname_apply="paiapply"
dbname_tenx="paiprod"

# Set the required environment variables
emailsender="u2j@10academy.org"
appkey=$(echo $RANDOM$RANDOM$RANDOM$RANDOM | base64 | head -c 30; echo)
appkeysalt=$(echo $RANDOM$RANDOM$RANDOM$RANDOM | base64 | head -c 30; echo)
src_public_suffix_apply="prod-paiapply-cms"
src_public_suffix="prod-pai-cms"
s3bucket="s3://all-tenx-system"


# Docker environment configurations
dockerenv1="-p $port1:$port11 --env REDIRECT_URL=https://${dns1} --env EMAIL_SENDER=${emailsender} --env DATABASE_NAME=${dbname_apply} --env DATABASE_HOST=u2jdb.cluster-crlafpfc5g5y.us-east-1.rds.amazonaws.com -v /mnt/all-tenx-system/src-${src_public_suffix_apply}:/opt/app/src -v /mnt/all-tenx-system/public-${src_public_suffix_apply}:/opt/app/public --env appkey=$appkey --env appkeysalt=$appkeysalt --env APP_KEYS=${appkey},${appkeysalt} --env API_TOKEN_SALT=$appkeysalt --env ADMIN_JWT_SECRET=$appkey"

dockerenv2="-p $port2:$port22 --env REDIRECT_URL=https://${dns2} --env EMAIL_SENDER=${emailsender} --env DATABASE_NAME=${dbname_apply} --env DATABASE_HOST=u2jdb.cluster-crlafpfc5g5y.us-east-1.rds.amazonaws.com -v /mnt/all-tenx-system/src-${src_public_suffix_apply}:/opt/app/src -v /mnt/all-tenx-system/public-${src_public_suffix_apply}:/opt/app/public --env appkey=$appkey --env appkeysalt=$appkeysalt --env APP_KEYS=${appkey},${appkeysalt} --env API_TOKEN_SALT=$appkeysalt --env ADMIN_JWT_SECRET=$appkey"

dockerenv3="-p $port3:$port33 --env REDIRECT_URL=https://${dns3} --env EMAIL_SENDER=${emailsender} --env DATABASE_NAME=${dbname_tenx} --env DATABASE_HOST=u2jdb.cluster-crlafpfc5g5y.us-east-1.rds.amazonaws.com -v /mnt/all-tenx-system/src-${src_public_suffix}:/opt/app/src -v /mnt/all-tenx-system/public-${src_public_suffix}:/opt/app/public --env appkey=$appkey --env appkeysalt=$appkeysalt --env APP_KEYS=${appkey},${appkeysalt} --env API_TOKEN_SALT=$appkeysalt --env ADMIN_JWT_SECRET=$appkey"

dockerenv4="-p $port4:$port44 --env REDIRECT_URL=https://${dns4} --env EMAIL_SENDER=${emailsender} --env DATABASE_NAME=${dbname_tenx} --env DATABASE_HOST=u2jdb.cluster-crlafpfc5g5y.us-east-1.rds.amazonaws.com -v /mnt/all-tenx-system/src-${src_public_suffix}:/opt/app/src -v /mnt/all-tenx-system/public-${src_public_suffix}:/opt/app/public --env appkey=$appkey --env appkeysalt=$appkeysalt --env APP_KEYS=${appkey},${appkeysalt} --env API_TOKEN_SALT=$appkeysalt --env ADMIN_JWT_SECRET=$appkey"


echo ""
echo "============================================"
echo "       Install COPY SSL CERT & SSH KEYS     "
echo "============================================"
echo ""

#copy cert  
aws s3 cp s3://all-tenx-system/ssl-certs/sectigo ./cert --recursive #| echo "ERROR: can not copy cert folder from s3"
mkdir -p /etc/ssl

if [ -d ./cert ]; then
   cp -r ./cert/* /etc/ssl/
fi



# Generate NGINX conf files
cat <<'EOF2' > /etc/nginx/conf.d/apply_cms.conf
server {
       listen 80;
       server_name apply.10academy.org;
       server_tokens off;


       location / {
        	 return 301 https://$host$request_uri;
    		 }
}


server {
    listen 443 ssl;
    server_name apply.10academy.org;
    server_tokens off;

    ssl_certificate /etc/ssl/ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/my-aws-private.key;

    # Redirect non-https traffic to https
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    
    location / {
        proxy_pass http://0.0.0.0:5173;
        #proxy_set_header Host $host;
        proxy_set_header    Host                $http_host;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    }
    
}
EOF2


cat <<'EOF2' > /etc/nginx/conf.d/apply.conf
server {
       listen 80;
       server_name apply.10academy.org;
       server_tokens off;


       location / {
        	 return 301 https://$host$request_uri;
    		 }
}


server {
    listen 443 ssl;
    server_name apply.10academy.org;
    server_tokens off;

    ssl_certificate /etc/ssl/ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/my-aws-private.key;

    # Redirect non-https traffic to https
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    
    location / {
        proxy_pass http://0.0.0.0:5173;
        #proxy_set_header Host $host;
        proxy_set_header    Host                $http_host;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    }
    
}
EOF2


cat <<'EOF2' > /etc/nginx/conf.d/tenx_cms.conf
server {
       listen 80;
       server_name apply.10academy.org;
       server_tokens off;


       location / {
        	 return 301 https://$host$request_uri;
    		 }
}


server {
    listen 443 ssl;
    server_name apply.10academy.org;
    server_tokens off;

    ssl_certificate /etc/ssl/ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/my-aws-private.key;

    # Redirect non-https traffic to https
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    
    location / {
        proxy_pass http://0.0.0.0:5173;
        #proxy_set_header Host $host;
        proxy_set_header    Host                $http_host;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    }
    
}
EOF2


cat <<'EOF2' > /etc/nginx/conf.d/tenx.conf
server {
       listen 80;
       server_name apply.10academy.org;
       server_tokens off;


       location / {
        	 return 301 https://$host$request_uri;
    		 }
}


server {
    listen 443 ssl;
    server_name apply.10academy.org;
    server_tokens off;

    ssl_certificate /etc/ssl/ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/my-aws-private.key;

    # Redirect non-https traffic to https
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    
    location / {
        proxy_pass http://0.0.0.0:5173;
        #proxy_set_header Host $host;
        proxy_set_header    Host                $http_host;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    }
    
}
EOF2


# sed replace server name with the correct server name
sed -i "s/apply.10academy.org/${dns1}/g" /etc/nginx/conf.d/apply_cms.conf
sed -i "s/apply.10academy.org/${dns2}/g" /etc/nginx/conf.d/apply.conf
sed -i "s/apply.10academy.org/${dns3}/g" /etc/nginx/conf.d/tenx_cms.conf
sed -i "s/apply.10academy.org/${dns4}/g" /etc/nginx/conf.d/tenx.conf

sed -i "s/5173/${port1}/g" /etc/nginx/conf.d/apply_cms.conf
sed -i "s/5173/${port2}/g" /etc/nginx/conf.d/apply.conf
sed -i "s/5173/${port3}/g" /etc/nginx/conf.d/tenx_cms.conf
sed -i "s/5173/${port4}/g" /etc/nginx/conf.d/tenx.conf

# Restart Nginx
systemctl daemon-reload
systemctl restart nginx



echo ""
echo "============================================"
echo "       Remove Old Containers and Start New    "
echo "============================================"
echo ""

# Stop and Remove all running containers
rlist=$(docker ps -aq)
if [[ ! -z $rlist ]]; then
   docker stop $rlist; docker rm $rlist
fi

# Run Docker containers
docker run $dockerenv1 --name ${dns1::-14} -d $apply_cms_image
docker run $dockerenv2 --name ${dns2::-14} -d $apply_tenx_image
docker run $dockerenv3 --name ${dns3::-14} -d $cms_image
docker run $dockerenv4 --name ${dns4::-14} -d $tenx_image


EOF