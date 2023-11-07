#Ref:
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html#container_agent_host
# https://blog.tedivm.com/guides/2020/07/aws-ecs-with-ubuntu-and-gpu-support/

#To check Missing attribute use something like
#ecs-cli check-attributes --container-instances "49c779786b464edfab763384db93a7d3" --task-def "prod-tgad-ecs-task:10" --cluster "ecs-prod-tgad-cluster" --region us-east-1 --aws-profile aiqem

#------------START: code to build from git------------
if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<EOF >>  $fout

echo ""
echo "============================================"
echo "    Install Awslog with config"
echo "============================================"
echo ""


#download CloudWatch Logs Agent deb
#ref; https://www.petefreitag.com/item/868.cfm
curl -o /root/amazon-cloudwatch-agent.deb https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb
#install it
dpkg -i -E /root/amazon-cloudwatch-agent.deb


#Add cwagent User to adm group
#usermod -aG adm cwagent

systemctl enable amazon-cloudwatch-agent.service
service amazon-cloudwatch-agent start

# allow the port proxy to route traffic using loopback addresses
sh -c "echo 'net.ipv4.conf.all.route_localnet = 1' >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf

#enable IAM roles for tasks
apt-get install iptables-persistent
iptables -t nat -A PREROUTING -p tcp -d 169.254.170.2 --dport 80 -j DNAT --to-destination 127.0.0.1:51679
iptables -t nat -A OUTPUT -d 169.254.170.2 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 51679

#Add an iptables route to block off-host access to the introspection API endpoint.
iptables -A INPUT -i eth0 -p tcp --dport 51678 -j DROP

#Write the new iptables configuration to operating system-specific location
sh -c 'iptables-save > /etc/iptables/rules.v4'

mkdir -p /etc/ecs
mkdir /data

touch /etc/ecs/ecs.config

cat <<EOFF >> /etc/ecs/ecs.config
ECS_DATADIR=/data
ECS_ENABLE_TASK_IAM_ROLE=true
ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true
ECS_LOGFILE=/var/log/ecs-agent.log
ECS_AVAILABLE_LOGGING_DRIVERS=["json-file","awslogs"]
ECS_LOGLEVEL=info
ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true
## -- other config ##
ECS_ENABLE_TASK_ENI=true

EOFF

sudo sysctl -p /etc/sysctl.conf



echo "============================================"
echo "    Install ECS Agent"
echo "============================================"


curl -o ecs-agent.tar https://s3.${region:-us-east-1}.amazonaws.com/amazon-ecs-agent-${region:-us-east-1}/ecs-agent-latest.tar

docker load --input ./ecs-agent.tar

# Write systemd unit file
cat << EOFF > /etc/systemd/system/docker-container@ecs-agent.service
[Unit]
Description=Docker Container %I
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStartPre=-/usr/bin/docker rm -f %i
ExecStart=/usr/bin/docker run --name %i \
--init \
--restart=on-failure:10 \
--volume=/var/run:/var/run \
--volume=/var/log/ecs/:/log \
--volume=/var/lib/ecs/data:/data \
--volume=/etc/ecs:/etc/ecs \
--volume=/sbin:/host/sbin \
--volume=/lib:/lib \
--volume=/lib64:/lib64 \
--volume=/usr/lib:/usr/lib \
--volume=/usr/lib64:/usr/lib64 \
--volume=/proc:/host/proc \
--volume=/sys/fs/cgroup:/sys/fs/cgroup \
--net=host \
--env-file=/etc/ecs/ecs.config \
--cap-add=sys_admin \
--cap-add=net_admin \
amazon/amazon-ecs-agent:latest
ExecStop=/usr/bin/docker stop %i


[Install]
WantedBy=default.target
EOFF

systemctl enable docker-container@ecs-agent.service
systemctl start docker-container@ecs-agent.service

# docker run --name ecs-agent \
#        --detach=true \
#        --volume=/var/run:/var/run \
#        --volume=/var/log/ecs/:/log \
#        --volume=/var/lib/ecs/data:/data \
#        --volume=/etc/ecs:/etc/ecs \
#        --net=host \
#        --env-file=/etc/ecs/ecs.config \
#        --restart always \
#        --env=ECS_LOGFILE=/log/ecs-agent.log \
#        --env=ECS_DATADIR=/data/ \
#        --env=ECS_ENABLE_TASK_IAM_ROLE=true \
#        --env=ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true \
#        --env=ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true \
#        amazon/amazon-ecs-agent:latest

EOF

