echo ""
echo "============================================"
echo "       Install COPY SSL CERT & SSH KEYS     "
echo "============================================"
echo ""

dnsprefix=${1:-autograde}
port=${2:-5000}

ssldirname=sectigo

#copy cert  
aws s3 cp s3://all-tenx-system/ssl-certs/sectigo ./cert --recursive #| echo "ERROR: can not copy cert folder from s3"
mkdir -p /etc/ssl

if [ -d ./cert ]; then
   cp -r ./cert/* /etc/ssl/
fi


echo ""
echo "============================================"
echo "           Install NGINX & Add app.conf     "
echo "============================================"
echo ""

#install nginx
if command -v apt-get >/dev/null; then
   apt-get -q install nginx -y 
else
   yum -q install nginx -y 
fi

cat <<EOF > app.conf
server {
       listen 80;
       server_name ${dnsprefix}.10academy.org;
       server_tokens off;
EOF
cat <<'EndOF' >> app.conf

       location / {
                 return 301 https://$host$request_uri;
                 }
}
EndOF
cat <<EOF >> app.conf
server {
    listen 443 ssl;
    server_name ${dnsprefix}.10academy.org;
    server_tokens off;
EOF
cat <<'EndOF' >> app.conf

    ssl_certificate /etc/ssl/ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/my-aws-private.key;

    # Redirect non-https traffic to https
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    } # managed by Certbot
EndOF
cat <<EOF >> app.conf
    
    location / {
        proxy_pass http://0.0.0.0:${port};
EOF
cat <<'EndOF' >> app.conf

        #proxy_set_header Host $host;
        proxy_set_header    Host                $http_host;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    }
    
}
EndOF

mkdir -p /etc/nginx/conf.d/
cp app.conf /etc/nginx/conf.d/${dnsprefix}.conf  #| echo "can not copy nginx conf to /etc/nginx/conf.d/"

systemctl daemon-reload
systemctl restart nginx
