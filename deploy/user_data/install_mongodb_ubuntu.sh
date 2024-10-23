#!/bin/bash


######## Run this bash script with to install Mongodb on your system ##########

# HOWTO:
	# System recommendation : Ubuntu 16.04	
	# Download the script
	# Open in bash and make it executable with command: chmod +x mongodb_install.sh
	# Run with command: sudo ./mongodb_install.sh

# OTHER USEFUL SCRIPTS:
	# For making a MongoDB replica set with three nodes: https://gist.github.com/Maria-UET/af4332f6dd9e57f2d0f6141dbb8dd447
	# For initating the MongoDB replica set after configuration: https://gist.github.com/Maria-UET/af4332f6dd9e57f2d0f6141dbb8dd447


if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<'EOF' >>  $fout

# Add an appropriate username for your MongoDB user
USR="admin"
# Add an appropriate password for your MongoDB user. Password should be ideally read from a config.ini file, keeping passwords in bash scripts is not secure.
PASS="test@admin"
DB="AIQEMAd"
ROLE="root"
BIND_IP=0.0.0.0

sudo apt update

echo ""
echo "installing mongodb dependencies"
sudo apt install gnupg wget apt-transport-https ca-certificates software-properties-common

echo ""
echo "Adding the MongoDB GPG key to your system"
wget -qO- https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor | sudo tee /usr/share/keyrings/mongodb-server-7.0.gpg >/dev/null

echo ""
echo "Creating a deb list file for MongoDB"
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | sudo tee -a /etc/apt/sources.list.d/mongodb-org-7.0.list

echo ""
echo "Installing MongoDB"
sudo apt update
sudo apt install mongodb-org

echo ""
echo "Starting MongoDB"
sudo systemctl enable mongod.service
sudo systemctl status mongod.service

echo ""
echo " ############################## Mongodb has been installed  ###############################"
echo " ##      Check status of mongod server by running this command: sudo netstat -plntu      ##"
echo " ##########################################################################################"
mongosh --eval 'db.runCommand({ connectionStatus: 1 })'


export LC_ALL=C


echo ""
echo "Creating mongodb user"
mongo admin --eval "db.createUser({'user':'$USR', 'pwd':'$PASS', 'roles':[{'role':'$ROLE', 'db':'$DB'}]})"


sudo systemctl stop mongod


echo ""
echo "Configuring the mongod.conf file to update bindip and enable authentication"
sudo sed -i[bindIp] "s/bindIp: /bindIp: $BIND_IP #/g" /etc/mongod.conf 
# Do not enable ip_bind_all without enabling authorization. otherwise, the db will be exposed.
sudo echo  "#authorization config
security:
   authorization: enabled" >> /etc/mongod.conf


echo ""
echo "Appending --auth to mongod.service to enable authentication"
sudo sed -i '/ExecStart/ s/$/ --auth/' /lib/systemd/system/mongod.service

sudo systemctl enable mongod.service


echo ""
echo "Initiating daemon-reload"
sudo systemctl daemon-reload


sudo service mongod stop


echo ""
echo "Starting the mongod server with the following parameters:"
echo "sudo mongod --bind_ip_all --fork --logpath /var/log/mongodb.log"
sudo mongod --bind_ip $BIND_IP --fork --logpath /var/log/mongodb.log


echo "Starting the mongo shell with following parameters:"
echo "mongo -u $USR -p $PASS"
mongo -u $USR -p $PASS 



echo "You can connect to this db from remote client using: mongo --username $USR --password $PASS ipaddress:27017/db_name --authenticationDatabase $DB"

EOF