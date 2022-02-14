if [ $# -eq 0 ]; then
    echo "Usage: ecs_deploy <path to params file>"
    exit 0
fi
if [ $# -gt 1 ]; then
    apporcert=$2
else
    apporcert='cert'    
fi
echo "Loading variables from $1"
source $1 #many key variables returned

domain=(${dns_namespace})

cert_path="./data/${root_name}/certbot"
nginx_path="./data/${root_name}/nginx"
docker_path="./data/${root_name}/docker"
mkdir -p $nginx_path/{cert,app}
mkdir -p $cert_path/{www,conf}
mkdir -p $docker_path/{cert,app}

#copy files with new names
cp -r data/nginx/snippets ${nginx_path}/
cp -r data/nginx/app/app.conf ${nginx_path}/app/app.conf
cp -r data/nginx/cert/cert.conf ${nginx_path}/cert/cert.conf
cp -r data/docker-compose-cert.yaml  $docker_path/cert/docker-compose.yaml
cp -r data/docker-compose.yaml  $docker_path/app/docker-compose.yaml

#edit files
sed -i""  "s/app.com/$domain/g" ${nginx_path}/cert/cert.conf
sed -i""  "s|./data/nginx|${nginx_path}|g" $docker_path/cert/docker-compose.yaml 
sed -i""  "s|./data/certbot|${cert_path}|g" $docker_path/cert/docker-compose.yaml
#
sed -i"" "s/app.com/$domain/g" ${nginx_path}/app/app.conf
sed -i""  "s|./data/nginx|${nginx_path}|g" $docker_path/app/docker-compose.yaml 
sed -i""  "s|./data/certbot|${nginx_path}|g" $docker_path/app/docker-compose.yaml 

if [ "$apporcert"=="cert" ]; then
    cp $docker_path/cert/docker-compose.yaml ./
else
    cp $docker_path/app/docker-compose.yaml ./
fi
