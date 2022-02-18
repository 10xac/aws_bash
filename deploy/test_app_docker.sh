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
###-------- Create a test Flask App and Dockerfile  -----##
##------------------------------------------------------#

mkdir -p output/test_app


#Define a simple hello service, with following content:
cat <<EOF > service.py
from flask import Flask
import socket

app = Flask(__name__)

@app.route('/service')
def hello():
  return (f'Hello from behind Envoy proxy!!\n')

if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8080, debug=True)
EOF

#Create a Dockerfile for the application container.
cat <<EOF > Dockerfile-app
FROM envoyproxy/envoy-alpine-dev:latest

RUN apk update && apk add python3 bash curl; \
      pip3 install -q Flask==0.11.1 requests==2.18.4; \
      mkdir /code

ADD ./service.py /code

EXPOSE 8080

CMD ["python3", "/code/service.py"]
EOF

#Let’s build the Docker images and push them to ECR.
docker build -t ${aws_ecr_repository_url_app} -f Dockerfile-app .

mv service.py Dockerfile-app output/test_app

