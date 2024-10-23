#!/bin/bash
echo ECS_CLUSTER=ecs-sre-board-cluster >> /etc/ecs/ecs.config;
echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
yum update -y

yum install nginx -y || echo "cant install nginx with yum"
amazon-linux-extras install nginx1.12 -y || echo "cant install nginx with amazon-linux-extras"
service nginx start

