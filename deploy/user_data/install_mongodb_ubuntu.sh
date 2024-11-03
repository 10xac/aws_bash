#!/bin/bash


######## Run this bash script with to install Mongodb on your system ##########

# HOWTO:
	# System recommendation : Ubuntu 16.04	
	# Download the script
	# Open in bash and make it executable with command: chmod +x mongodb_install.sh
	# Run with command: ./mongodb_install.sh

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
# Add an appropriate password for your MongoDB user. 
# Password should be ideally read from a config.ini file, 
# keeping passwords in bash scripts is not secure.
USR="admin"
PASS="test@admin"
DB="admin"
DBDATA="AiQEMAd"
ROLE="root"
BIND_IP=0.0.0.0
BUCKET="s3://tgad-mongodb-backup"

function restore_latest_backup {
        KEY=$(aws s3 ls $BUCKET/tgad_mongodb_backup/ --recursive  | sort | tail -n 1 | awk '{print $4}')
        backup_filename=$(basename $KEY)
        echo "=============STARTING RESTORE=================="
        echo "Getting latest backup from s3 $BUCKET/$KEY .."
        aws s3 cp $BUCKET/$KEY ./ 
        mkdir -p backup & cd backup
	unzip $BUCKET/$KEY
	cd ../
        echo "Restoring $DB "
        #mongorestore --gzip --archive=$backup_filename --nsInclude="$DBDATA.*" --drop
	mongorestore -u $USR -p $PASS --authenticationDatabase $DB --drop --dir backup/
        echo "Done Restoring!"
	echo "=============RESTORE COMPLETED=================="
}


## Write a bash script to schedule a cron job to 
## backup the mongodb database and store it in the s3 bucket
cat <<EOFF > $HOME/mongodb_backup.sh
#!/bin/bash

# Get the current date and time
datetime=$(date +"%Y%m%d_%H%M%S")

echo "$(date +"%Y-%m-%d_%H-%M-%S"): Backing up in $latest_backup" >> log.txt

latest_backup="aiqemad_mongodb_backup_latest.zip"
mongodump --db $DB  --gzip --archive > $latest_backup

aws s3 cp $latest_backup $BUCKET/tgad_mongodb_backup/mongodb_backup_$datetime.zip

echo "$(date +"%Y-%m-%d_%H-%M-%S"): Backed up!" >> log.txt
EOFF

echo ""
echo "Setting up the cron job to backup the mongodb database"
chmod +x $HOME/mongodb_backup.sh
#(crontab -l 2>/dev/null; echo "0 0/6 * * * $HOME/mongodb_backup.sh") | crontab -



echo ""
echo "Creating a deb list file for MongoDB"
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/8.0 multiverse" \
	| tee /etc/apt/sources.list.d/mongodb-org-8.0.list


echo ""
echo "Installing MongoDB"
apt-get -y update 
apt-get -y install mongodb-org mongodb-org-database \
				  mongodb-org-server mongodb-mongosh \
				  mongodb-org-mongos mongodb-org-tools

echo ""
echo "Set the right permission settings"
chown -R mongodb:mongodb /var/lib/mongodb
service mongod restart

echo ""
echo "Starting MongoDB"
systemctl enable mongod.service
systemctl status mongod.service

export LC_ALL=C

echo ""
echo " ############################## Mongodb has been installed  ###############################"
echo " ##      Check status of mongod server by running this command: netstat -plntu      ##"
echo " ##########################################################################################"
mongosh --eval 'db.runCommand({ connectionStatus: 1 })'



echo ""
echo "Restore from latest backup"
restore_latest_backup

echo ""
echo "Creating a user with name=$USR and role=$ROLE:"
mongosh admin --eval "db.createUser({'user':'$USR', 'pwd':'$PASS', 'roles':[{'role':'$ROLE', 'db':'$DB'}]})"


systemctl stop mongod


echo ""
echo "Configuring the mongod.conf file to update bindip and enable authentication"
sed -i[bindIp] "s/bindIp: /bindIp: $BIND_IP #/g" /etc/mongod.conf 
# Do not enable ip_bind_all without enabling authorization. otherwise, the db will be exposed.
echo  "#authorization config
security:
   authorization: enabled" >>  /etc/mongod.conf

echo ""
echo "Appending --auth to mongod.service to enable authentication"
sed -i '/ExecStart/ s/$/ --auth/' /lib/systemd/system/mongod.service

systemctl enable mongod.service


echo ""
echo "Initiating daemon-reload"
systemctl daemon-reload


service mongod stop


echo ""
echo "Starting the mongod server with the following parameters:"
echo "mongod --bind_ip_all --fork --logpath /var/log/mongodb.log"
mongod --bind_ip $BIND_IP --fork --logpath /var/log/mongodb.log


echo "Starting the mongo shell with following parameters:"
echo "mongosh -u $USR -p $PASS"
mongosh -u $USR -p $PASS 

chown -R mongodb:mongodb /var/lib/mongodb
chown mongodb:mongodb /tmp/mongodb-27017.sock
service mongod restart


echo "You can connect to this db from remote client using: mongosh --username $USR --password $PASS 127.0.0.1:27017/$DBDATA --authenticationDatabase $DB"

EOF