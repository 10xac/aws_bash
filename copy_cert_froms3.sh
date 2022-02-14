
mkdir -p ./data/sre-board/certbot
mkdir -p ./data/sre-board/nginx/app

#copy cert  
aws s3 cp s3://ml-box-data/ssl-certs/sre-board ./data/sre-board/certbot/conf --recursive
aws s3 cp s3://ml-box-data/nginx/sre-board ./data/sre-board/nginx/app --recursive 


if [ -d ./cert ]; then
   cp -r ./cert /etc/ssl/letsencrypt
fi
