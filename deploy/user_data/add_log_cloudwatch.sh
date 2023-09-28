#Ref:
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html#container_agent_host
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

cat <<'EOFF' >> /opt/aws/amazon-cloudwatch-agent/bin/config.json
{
        "agent": {
                "metrics_collection_interval": 60,
                "run_as_user": "root"
        },
        "logs": {
                "logs_collected": {
                        "files": {
                                "collect_list": [
                                        {
                                                "file_path": "/var/log/ecs-agent.log",
                                                "log_group_name": "ecs-agent-log-group",
                                                "log_stream_name": "{instance_id}/agent.log",
                                                "retention_in_days": -1
                                        },
                                        {                                       
                                        	"file_path": "/var/log/nginx/access.log",
                                                "log_group_name": "web-server-log-group",
                                                "log_stream_name": "{instance_id}/access.log",
                                                "timestamp_format" :"[%d/%b/%Y:%H:%M:%S %z]",
                                                "retention_in_days": -1
                                        },
                                        {
                                        	"file_path": "/var/log/nginx/error.log",
                                               	"log_group_name": "web-server-log-group",
                                               	"log_stream_name": "{instance_id}/error.log",
                                               	"timestamp_format" :"[%d/%b/%Y:%H:%M:%S %z]",
                                                "retention_in_days": -1
                                        }
                                ]
                        }
                }
        },
        "metrics": {
                "aggregation_dimensions": [
                        [
                                "InstanceId"
                        ]
                ],
                "append_dimensions": {
                        "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
                        "ImageId": "${aws:ImageId}",
                        "InstanceId": "${aws:InstanceId}",
                        "InstanceType": "${aws:InstanceType}"
                },
                "metrics_collected": {
                        "collectd": {
                                "metrics_aggregation_interval": 60
                        },
                        "disk": {
                                "measurement": [
                                        "used_percent"
                                ],
                                "metrics_collection_interval": 60,
                                "resources": [
                                        "*"
                                ]
                        },
                        "mem": {
                                "measurement": [
                                        "mem_used_percent"
                                ],
                                "metrics_collection_interval": 60
                        },
                        "statsd": {
                                "metrics_aggregation_interval": 60,
                                "metrics_collection_interval": 60,
                                "service_address": ":8125"
                        }
                }
        }
}
EOFF

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

EOFF

sudo sysctl -p /etc/sysctl.conf


EOF
