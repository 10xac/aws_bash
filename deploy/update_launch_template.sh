
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
if [[ "$OSTYPE" == "darwin"* ]]; then
    SEDOPTION="-i ''"
else
    SEDOPTION="-i "
fi

fnameuserdata=$configoutputdir/${root_name}_user_data.sh

#write modified user_data file
cat <<'EOF' >  $fnameuserdata
#!/bin/bash

if [[ -f /var/log/cloud-init-output.log ]]; then
  echo "--------starting new---------" > /var/log/cloud-init-output.log
fi


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

source $HOME/.bashrc


EOF

cat <<EOF >>  $fnameuserdata
echo ""
echo "============================================"
echo "          SET ECS_CLUSTER ENV               "
echo "============================================"
echo ""

mkdir -p /etc/ecs

echo ECS_CLUSTER=${ecs_cluster_name} > /etc/ecs/ecs.config;
echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;


EOF


if ${setup_nginx:-true} ; then
cat <<EOF >>  $fnameuserdata
echo ""
echo "============================================"
echo "           Update NGINX & Add app.conf     "
echo "============================================"
echo ""


cat <<'EndOF' > app.conf
server {
       listen 80;
       server_name ${nginxservername};
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
if ${copy_ssl_cert_froms3} ; then
cat <<EOF >>  $fnameuserdata
server {
    listen 443 ssl;
    server_name ${nginxservername};
    server_tokens off;

EOF
if [[ $(basename $s3certpath) == "sectigo" ]] ; then
cat <<EOF >>  $fnameuserdata
    ssl_certificate /etc/ssl/ssl-bundle.crt;
    ssl_certificate_key /etc/ssl/my-aws-private.key;
EOF
else
cat <<EOF >>  $fnameuserdata
    ssl_certificate /etc/ssl/letsencrypt/live/${ssldnsname}/fullchain.pem;
    ssl_certificate_key /etc/ssl/letsencrypt/live/${ssldnsname}/privkey.pem;
    #include /etc/ssl/letsencrypt/options-ssl-nginx.conf;
    #ssl_dhparam /etc/ssl/letsencrypt/ssl-dhparams.pem;

EOF
fi
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
EOF

fi  #if ssl copy cert

cat <<EOF >>  $fnameuserdata
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
userdata=$(base64 -i $fnameuserdata)
#echo "----UserData base64 hash----"
#echo $userdata

#replace line userdata in template
ftemplate=$configoutputdir/${root_name}-launch-template.json

#if [ ! -f $ftemplate ]; then
#check https://docs.aws.amazon.com/cli/latest/reference/ec2/create-launch-template.html
if [ -f template/${root_name}-launch-template.json ]; then
    cp ./template/${root_name}-launch-template.json ${ftemplate}
else
    envsubst <${ec2LaunchTemplate}>$ftemplate
fi
#fi


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

