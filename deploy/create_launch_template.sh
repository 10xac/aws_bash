#--------------------------------------------------------#
###-----Define necessary environment variables if passed -----##
##------------------------------------------------------#
if [ ! -z "$1" ]; then        
    echo "Loading variables from $1"
    source $1 #many key variables returned
    source create_conflog_dir.sh ""
    echo "confdir=$configoutputdir"
    echo "logdir=$logoutputdir"    
fi

#---- use 
certpath=${s3bucket}/ssl-certs/${root_name}    
if [ "${ENV:-prod}" == "dev" ]; then
    certpath=${s3bucket}/ssl-certs/dev-${root_name}
elif [ "${ENV:-prod}" == "stag" ]; then
    certpath=${s3bucket}/ssl-certs/stagin-${root_name}
fi
s3certpath=${s3certpath:-$certpath}

localcertdir=$configoutputdir/certs
fnameuserdata=$configoutputdir/${root_name}_user_data.sh

#copy cert to s3 
if [ -f ${localdir}/my-aws-private.key ]; then
    echo "cpying SSL certs from output/certs/${root_name} to #s3path.."
    
    aws s3 cp ${localcertdir} $s3certpath --recursive --profile ${profile_name}
fi


#write modified user_data file
cat <<EOF >  $fnameuserdata
#!/bin/bash
mkdir -p /etc/ecs
echo ECS_CLUSTER=${ecs_cluster_name} >> /etc/ecs/ecs.config;
echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;

if command -v apt-get >/dev/null; then
   apt -qq update -y
   apt -qq install fuse -y 
   apt -qq install git -y
   apt -qq install jq -y
   apt -qq install unzip -y
else
   yum -qq update -y
   yum -qq install fuse -y
   yum -qq install git -y
   yum -qq install jq -y 
   yum -qq install unzip -y
fi

#write aws config file
cat <<EOFF >  config
[default]
s3 =
   signature_version = s3v4
region = $region

[profile $profile_name]
region = $region
output = json
EOFF

EOF

#--------
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

if [ -d $home ]; then
    homeUser=$(basename $home)
else
    homeUser=`whoami`
fi

#copy aws config file 
mkdir -p $HOME/.aws $home/.aws
cp config $HOME/.aws 
cp config $home/.aws

#set path
echo PATH=/usr/bin:/usr/local/bin:$PATH >> $HOME/.bashrc
echo PATH=/usr/bin:/usr/local/bin:$PATH >> $home/.bashrc

echo 'alias emacs="emacs -nw"' >> $HOME/.bashrc
echo 'alias emacs="emacs -nw"' >> $home/.bashrc

source $HOME/.bashrc

#--------update aws cli
function awscli_install(){    
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -qq awscliv2.zip
    ./aws/install --update
    #
    if [ -f /usr/bin/aws ]; then
        rm /usr/bin/aws || echo ""
    fi
    #
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


if ${ec2launch_install_docker:-true} ; then

    echo "appending docker install in $fnameuserdata"
    
cat <<'EOF' >>  $fnameuserdata

#install docker
if command -v docker >/dev/null; then
	echo "docker is already installed"
else
    if [ -f /usr/local/bin/docker ]; then
	echo "adding /usr/local/bin in PATH as docker is already installed there"
	echo "Consider sourcing $home/.bashrc in your shell"
	echo "export PATH=/usr/local/bin:$PATH" >> $home/.bashrc
	source $home/.bashrc
    else    
	echo "installing docker .."
	if command -v apt-get >/dev/null; then
	    apt-get -qq update -y
	    apt-get -qq install -y docker.io
	    systemctl docker start
	    usermod -aG docker ${homeUser}
	    
	elif command -v yum >/dev/null; then
	    yum -qq update -y
	    yum -qq install -y docker
	    systemctl docker start
	    usermod -aG docker ${homeUser}
	else
	    echo "unknown os system.."
	    #exit
	fi
    fi
fi

#install docker-compose
if command -v docker-compose >/dev/null; then
	echo "docker-compose is already installed"
else
    if [ -f /usr/local/bin/docker-compose ]; then
	echo "adding /usr/local/bin in PATH as docker-compose is already installed there"
	echo "Consider sourcing $home/.bashrc in your shell"
	echo "export PATH=/usr/local/bin:$PATH" >> $home/.bashrc
	source $home/.bashrc
    else
	echo "installing docker-compose .."	
	curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
    fi
fi

docker --version
docker-compose --version
if [ -f /var/run/docker.sock ]; then
    chmod 777 /var/run/docker.sock
fi

## Amazon ECR Docker Credential Helper
if command -v apt-get >/dev/null; then
   apt -q install amazon-ecr-credential-helper
else
   if command -v amazon-linux-extras >/dev/null; then
      amazon-linux-extras enable docker 
   fi    
   yum -q install amazon-ecr-credential-helper
fi

cat <<EOFF > config.json
{
	"credsStore": "ecr-login"
}
EOFF
cp config.json $HOME/.aws 
cp config.json $home/.aws

EOF
fi

if $copy_ssl_cert_froms3 ; then
cat <<EOF >>  $fnameuserdata

#copy cert  
aws s3 cp $s3certpath ./cert --recursive #| echo "ERROR: can not copy cert folder from s3"
mkdir -p /etc/ssl

if [ -d ./cert ]; then
   cp -r ./cert /etc/ssl/letsencrypt
fi

#copy ssh key 
for s3akp in $s3_authorized_keys_path; do
EOF
cat <<'EOF' >>  $fnameuserdata
   if [ ! -z $s3akp ]; then
      aws s3 cp $s3akp - >> $home/.ssh/authorized_keys #| echo "ERROR: can not copy authorization key from s3"
   fi
done


EOF
fi

if ${setup_nginx:-$copy_ssl_cert_froms3} ; then
cat <<EOF >>  $fnameuserdata

#install nginx
if command -v apt-get >/dev/null; then
   apt-get -q install nginx -y 
else
   yum -q install nginx -y 
fi

cat <<'EndOF' > app.conf
server {
       listen 80;
       server_name ${dns_namespace};
       server_tokens off;

EOF

#---------
cat <<'EOF' >>  $fnameuserdata

       location / {
        	 return 301 https://$host$request_uri;
    		 }
}


EOF
#---------
cat <<EOF >>  $fnameuserdata
server {
    listen 443 ssl;
    server_name ${dns_namespace};
    server_tokens off;

    #ssl_certificate /etc/ssl/my-aws-public.crt;
    #ssl_certificate_key /etc/ssl/my-aws-private.key;
    #ssl_dhparam /etc/ssl/dhparam.pem;

    ssl_certificate /etc/ssl/letsencrypt/live/${certdnsname:-dns_namespace}/fullchain.pem;
    ssl_certificate_key /etc/ssl/letsencrypt/live/${certdnsname:-dns_namespace}/privkey.pem;
    include /etc/ssl/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/ssl/letsencrypt/ssl-dhparams.pem;

EOF
#-------
cat <<'EOF' >>  $fnameuserdata

    # Redirect non-https traffic to https
    if ($scheme != "https") {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    
    location / {
EOF
cat <<EOF >>  $fnameuserdata
        proxy_pass http://0.0.0.0:${ecsContainerPort:-80};
EOF
cat <<'EOF' >>  $fnameuserdata
        #proxy_set_header Host $host;
        proxy_set_header    Host                $http_host;
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
    }
    
}

EndOF

mkdir -p /etc/nginx/conf.d/
cp app.conf /etc/nginx/conf.d/  #| echo "can not copy nginx conf to /etc/nginx/conf.d/"

systemctl restart nginx

EOF

fi

#add extra userdata from file
if (( ${#extrauserdata[@]} )); then
    echo "$extrauserdata is passed to add to user_data .."
    for eud in $extrauserdata; do
        if [ -f $eud ]; then        
            bash $eud $fnameuserdata
            echo "ec2 user data $eud appended to $fnameuserdata "        
        fi
    done

if ${setup_nginx:-$copy_ssl_cert_froms3} ; then    
cat <<EOF >>  $fnameuserdata
systemctl restart nginx

EOF
fi
    
else
    echo "extrauserdata param is empty - not adding extra userdata from file"
fi


#convert user data to base64
userdata=$(base64 $fnameuserdata)
#echo "----UserData base64 hash----"
#echo $userdata

#replace line userdata in template
ftemplate=$configoutputdir/${root_name}-launch-template.json

#if [ ! -f $ftemplate ]; then
#check https://docs.aws.amazon.com/cli/latest/reference/ec2/create-launch-template.html
if [ -f template/${root_name}-launch-template.json ]; then
    cp ./template/${root_name}-launch-template.json $ftemplate        
else
    envsubst <${ec2LaunchTemplate}>$ftemplate    
fi
#fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    SEDOPTION="-i ''"
else
    SEDOPTION="-i "
fi

#now replace userdata
if [ -f $ftemplate ] ; then
    #echo "current dir: `pwd`"
    echo "writing launch template file: $ftemplate"
    sed $SEDOPTION "s|\"LaunchTemplateName.*|\"LaunchTemplateName\":\"$AsgTemplateName\",|" "$ftemplate"
    sed $SEDOPTION "s|.*ds-team-instance.*|\"Value\": \"${root_name}-host\"|" "$ftemplate"
    sed $SEDOPTION "s|\"UserData.*|\"UserData\":\"$userdata\",|" "$ftemplate"
else
    echo "ERROR: $ftemplate does not exist!"
fi


if [ "$1" == "norun" ]; then
    exit 0
fi

## get current ASG template if exists
res=$(aws ec2 describe-launch-template-versions \
          --launch-template-name $AsgTemplateName \
          --region $region --profile ${profile_name} \
          || echo "")

if (( ${#res[@]} )); then #not empty
    tnexist=$(echo $res | jq -r '.LaunchTemplateVersions | length>0')
else
    tnexist=false    
fi

if [ -z $tnexist ]; then
    echo "--- describe-launch-template result: -------"
    echo $res
    tnexist=false;
fi

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
          --region $region \
          --profile ${profile_name})

echo $res > $logoutputdir/output-create-launch-template.json     


res=$(aws ec2 describe-launch-template-versions \
          --launch-template-name $AsgTemplateName \
          --versions '$Latest' \
          --region $region --profile ${profile_name}
   )
echo $res > $logoutputdir/output-describe-launch-template-latest.json

AsgTemplateId=$(echo $res | jq -r '.LaunchTemplateVersions[0].LaunchTemplateId')

#to file
echo "export AsgTemplateId=$AsgTemplateId" > $logoutputdir/clt_output_params.sh
source $logoutputdir/clt_output_params.sh

#info
echo "ASG Launch template_name=$AsgTemplateName, template_id=$AsgTemplateId"

#update asg if template has been updated
source create_asg.sh ""

