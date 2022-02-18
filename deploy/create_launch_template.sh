#--------------------------------------------------------#
###-----Define necessary environment variables if passed -----##
##------------------------------------------------------#
if [ ! -z "$1" ]; then        
    echo "Loading variables from $1"
    source $1 #many key variables returned
    source create_conflog_dir.sh $root_name
    echo "confdir=$configoutputdir"
    echo "logdir=$logoutputdir"    
fi


s3certpath=${s3bucket}/ssl-certs/${root_name}
localcertdir=$configoutputdir/certs
fnameuserdata=$configoutputdir/${root_name}_user_data.template

#copy cert to s3 
if [ -f ${localdir}/my-aws-private.key ]; then
    echo "cpying SSL certs from output/certs/${root_name} to #s3path.."
    
    aws s3 cp ${localcertdir} $s3certpath --recursive --profile ${profile_name}
fi


#write modified user_data file
cat <<EOF >  $fnameuserdata
#!/bin/bash
echo ECS_CLUSTER=ecs-${ecs_cluster_name} >> /etc/ecs/ecs.config;
echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
yum update -y

EOF
cat <<'EOF' >>  $fnameuserdata

home=$HOME
if command -v apt-get >/dev/null; then
    if [ -d /home/ubuntu ]; then
        home=/home/ubuntu
    fi
else
    if [ -d /home/centos ]; then
        home=/home/centos
    fi
    if [ -d /home/ec2-user ]; then
        home=/home/ec2-user
    fi
    if [ -d /home/hadoop ]; then
        home=/home/hadoop
    fi    
fi

echo PATH=/usr/bin:/usr/local/bin:$PATH >> $HOME/.bashrc
echo PATH=/usr/bin:/usr/local/bin:$PATH >> $home/.bashrc
source $HOME/.bashrc


#--------update aws cli
pip3 install botocore --upgrade || echo "unable to upgrade botocore"
function awscli_install(){
    yum install unzip -y 
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install --update
    if [ -f /usr/bin/aws ]; then
        rm /usr/bin/aws || echo "unable to remove aws"
    fi    
    ln -s /usr/local/bin/aws /usr/bin/aws
    rm -rf .aws
}
if command -v aws >/dev/null; then
   if [[ $(aws --version) = aws-cli/1.* ]]; then
       awscli_install  || echo "unable to install cli"
   fi
else
   awscli_install  || echo "unable to install cli"     
fi

EOF


if $copy_ssl_cert_froms3 ; then
cat <<EOF >>  $fnameuserdata

#install nginx
yum install nginx -y 

#|| echo "cant install nginx with yum"

#copy cert  
aws s3 cp $s3certpath ./cert --recursive #| echo "ERROR: can not copy cert folder from s3"
mkdir -p /etc/ssl

#copy ssh key 
if [ ! -z "s3_authorized_keys_path" ]; then
aws s3 cp $s3_authorized_keys_path - >> ~/.ssh/authorized_keys #| echo "ERROR: can not copy authorization key from s3"
fi

if [ -d ./cert ]; then
   cp -r ./cert /etc/ssl/letsencrypt
fi

cat <<'EndOF' > app.conf
server {
       listen 80;
       server_name ${dns_namespace};
       server_tokens off;

EOF
cat <<'EOF' >>  $fnameuserdata

       location / {
        	 return 301 https://$host$request_uri;
    		 }
}

EOF
cat <<EOF >>  $fnameuserdata

server {
    listen 443 ssl;
    server_name ${dns_namespace};
    server_tokens off;

    #ssl_certificate /etc/ssl/my-aws-public.crt;
    #ssl_certificate_key /etc/ssl/my-aws-private.key;
    #ssl_dhparam /etc/ssl/dhparam.pem;

    ssl_certificate /etc/ssl/letsencrypt/live/${dns_namespace}/fullchain.pem;
    ssl_certificate_key /etc/ssl/letsencrypt/live/${dns_namespace}/privkey.pem;
    include /etc/ssl/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/ssl/letsencrypt/ssl-dhparams.pem;

EOF
cat <<'EOF' >>  $fnameuserdata

    # Redirect non-https traffic to https
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    
    location / {
        proxy_pass http://localhost:80;
        #proxy_set_header Host $host;
        proxy_set_header    Host                $http_host;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    }
    
}

EndOF

mkdir -p /etc/nginx/conf.d/
cp app.conf /etc/nginx/conf.d/  #| echo "can not copy nginx conf to /etc/nginx/conf.d/"
amazon-linux-extras install nginx1.12 -y || echo "cant install nginx with amazon-linux-extras"
service nginx start

EOF

fi

#convert user data to base64
userdata=$(base64 -w 0 $fnameuserdata )
#echo "----UserData base64 hash----"
#echo $userdata

#replace line userdata in template
ftemplate=$configoutputdir/${root_name}-launch-template.json

#if [ ! -f $ftemplate ]; then
if [ -f template/${root_name}-launch-template.json ]; then
    cp ./template/${root_name}-launch-template.json $ftemplate        
else
    envsubst <${ec2LaunchTemplate}>$ftemplate    
fi
#fi

#now replace userdata
if [ -f $ftemplate ] ; then
    echo "current dir: `pwd`"
    echo "writing launch template file: $ftemplate"
    sed -i'' "s|\"LaunchTemplateName.*|\"LaunchTemplateName\":\"$AsgTemplateName\",|" "$ftemplate"
    sed -i'' "s|.*ds-team-instance.*|\"Value\": \"${root_name}-host\"|" "$ftemplate"
    sed -i'' "s|\"UserData.*|\"UserData\":\"$userdata\",|" "$ftemplate"
else
    echo "ERROR: $ftemplate does not exist!"
fi


if [ $# > 0 ]; then
    exit 0
fi

## get current ASG template if exists
res=$(aws ec2 describe-launch-template-versions \
          --launch-template-name $AsgTemplateName \
          --region $region --profile ${profile_name}
   )

tnexist=$(echo $res | jq -r '.LaunchTemplateVersions | length>0') | false
echo "Does EC2 Launch Template Name: $AsgTemplateName exist?  $tnexist"

if $tnexist; then
    echo "deleting existing launch template .."
    aws ec2 delete-launch-template --launch-template-name $AsgTemplateName \
        --region $region --profile ${profile_name}    
    # res=$(aws ec2 modify-launch-template --launch-template-name $AsgTemplateName \
    #     --cli-input-json file://$ftemplate \
    #     --region $region --profile ${profile_name})
    # echo $res > $logoutputdir/output-modify-launch-template.json        
fi

echo "creating launch template .."
res=$(aws ec2 create-launch-template \
          --cli-input-json file://$ftemplate \
          --region $region --profile ${profile_name})

echo $res > $logoutputdir/output-create-launch-template.json     


res=$(aws ec2 describe-launch-template-versions \
          --launch-template-name $AsgTemplateName \
          --versions '$Latest' \
          --region $region --profile ${profile_name}
   )
echo $res > $logoutputdir/output-describe-launch-template-latest.json

export AsgTemplateId=$(echo $res | jq -r '.LaunchTemplateVersions[0].LaunchTemplateId')

#to file
echo "export AsgTemplateId=$AsgTemplateId" > $logoutputdir/clt_output_params.sh

#info
echo "ASG Launch template_name=$AsgTemplateName, template_id=$AsgTemplateId"
