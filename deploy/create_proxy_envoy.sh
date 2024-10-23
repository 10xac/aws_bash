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


#--------------------------------------------------------#
###-------- Create an Envoy configuration file. -----##
##------------------------------------------------------#

mkdir -p output/envoy-proxy


# It will used for proxying and routing requests.
# All requests from ALB will encrypted using TLS.
# The proxy will route requests to the application container over HTTP.
cat <<EOF > envoy.yaml
static_resources:
  listeners:
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 443
    filter_chains:
      tls_context:
        common_tls_context:
          tls_certificates:
          - certificate_chain:
              filename: "/etc/ssl/my-aws-public.crt"
            private_key:
              filename: "/etc/ssl/my-aws-private.key"
      filters:
      - name: envoy.http_connection_manager
        config:
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: service
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/"
                route:
                  cluster: local_service
          http_filters:
          - name: envoy.router
            config: {}
  clusters:
  - name: local_service
    connect_timeout: 0.5s
    type: strict_dns
    lb_policy: round_robin
    hosts:
    - socket_address:
        address: 127.0.0.1
        port_value: 8080

admin:
  access_log_path: "/dev/null"
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 8081
EOF

#Create a startup script to run Envoy.
cat <<EOF > start_envoy.sh
#!/bin/sh
/usr/local/bin/envoy -c /etc/envoy.yaml
EOF

#--------------------------------------------------------#
###-------- Create a Dockerfile for the Envoy proxy. -----##
##------------------------------------------------------#

#Create a Dockerfile for the Envoy proxy.
cat <<EOF > Dockerfile-proxy
FROM envoyproxy/envoy-dev:latest

RUN apt-get update && apt-get -q install -y \
    curl wget jq python \
        python-pip \
        python-setuptools \
        groff \
        less \
        && pip --no-cache-dir install --upgrade awscli
RUN mkdir -p /etc/ssl
ADD start_envoy.sh /start_envoy.sh
ADD envoy.yaml /etc/envoy.yaml
ADD certs /etc/ssl/

RUN chmod +x /start_envoy.sh

ENTRYPOINT ["/bin/sh"]
EXPOSE 443
CMD ["start_envoy.sh"]
EOF

#Let’s build the Docker images and push them to ECR.
## Build images locally, make sure you are in the docker folder
docker build -t ${aws_ecr_repository_url_proxy} -f Dockerfile-proxy .

mv envoy.yaml start_envoy.sh Dockerfile-proxy output/envoy-proxy
