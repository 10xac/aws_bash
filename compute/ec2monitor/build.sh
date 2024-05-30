#sudo chmod 777 -R ../tenx_auto_grade

target=${1:-"api"}
buildtype=${2:-"local"}

source env_setup.sh
echo "build.sh: using envfile=$envfile.."
build_arg=""
#build_arg=$(grep "GITHUB" $envfile | sed 's@^@--build-arg @g' | tr -d \" | paste -s -d " ")
#build_arg="${build_arg} --build-arg CACHEBUST=$(date +%s)"
#echo "build_arg=$build_arg"
function make_general_dockerfile(){
cat <<EOF > Dockerfile
FROM python:3.10

RUN pip install --upgrade pip

WORKDIR /app

COPY requirements.txt ./requirements.txt
RUN pip install -r ./requirements.txt


###copy all files in currrent dir to WORKDIR/
COPY . .

RUN chmod +x /app/ec2monitor.py

ENV STRAPI_STAGE="dev"

EXPOSE ${1}

# CMD ["/app/ec2monitor.py"]
# ENTRYPOINT ["python3"]

#CMD ["sh", "-c", "echo Starting ec2monitor && /app/ec2monitor.py"]
CMD ["python3", "-u", "ec2monitor.py"]

EOF
}


#========================================= 
#       write Dockerfile
#=========================================

echo "Using Dockerfile for General ... "
name="ec2monitor"
port=6000
tport=6000
make_general_dockerfile $port

#
echo "name=$name"
echo "port=$port"

#=========================================
#       write docker-compose.yml
#=========================================

cat <<EOF > docker-compose.yml
version: "3"
services:
  $name:
    container_name: $name
    build: .
    image: $name:latest
    restart: unless-stopped
    expose:
      - $tport 
    ports:
      - "$port:$tport"

EOF

#    network_mode: "host"    

#-----------------------------------------------
#---- build Strapi CMS ------------
#-----------------------------------------------
docker-compose down -t 0 $name

res=$(docker ps -aq)
if [ ! -z $res ]; then
    docker rm $res
fi


docker-compose build ${build_arg} $name
docker-compose up --remove-orphans --force-recreate -d $name
docker ps

echo "----- Logs so far ..-----"
echo "docker logs -f $(docker ps | head -2 | tail -1 | cut -d " " -f 1)"
docker logs -f $(docker ps | head -2 | tail -1 | cut -d " " -f 1)



echo ""
