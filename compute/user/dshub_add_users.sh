home=${ADMIN_HOME:-$(ls /home | awk 'NR==1{print $1}')}
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ -d $home ]; then
    homeUser=$(basename $home)
else
    homeUser=`whoami`
fi

if [ $# -gt 0 ]; then
    userfile=$1
else
    echo "no user file is provided!"
    exit 0
fi

#copy of if userfule is in s3
if [[ $userfile == s3://* ]]; then
    aws s3 cp $userfile ./
    userfile=$(basename $userfile)
else
    if [[ ! $userfile = ${scriptDir}* ]]; then
        userfile="$scriptDir/$userfile"
    fi    
fi

if [ ! -f $userfile ]; then
    echo "Users file ${userfile} does not exist: "
    exit 0
fi

BUCKET="${BUCKET:-ml-box-data}"
CREDROOTFOLDER="${CRED_ROOT_FOLDER:-$BUCKET/creds}"
NOTEBOOKFOLDER="${NOTEBOOK_FOLDER:-$BUCKET/emr-notebooks}"
CREDFOLDERS="${CRED_FOLDERS:-aws adludio}"
CREDENVFILES="${CRED_ENV_FILES:-}" 

function copy_user_creds(){
    n=$1
    HOME=/home/$1
    for folder in $CREDFOLDERS; do        
        if [ -d /mnt/$CREDROOTFOLDER/$folder ]; then
            mkdir $HOME/.$folder || echo "~/.$folder exists"        
            cp -r /mnt/$CREDROOTFOLDER/$folder/* $HOME/.$folder/
        fi    
    done
    
    for file in $CREDENVFILES; do        
        if [ -d /mnt/$CREDROOTFOLDER/$file ]; then
            mkdir $HOME/.env || echo "~/.$folder exists"        
            cp -r /mnt/$CREDROOTFOLDER/$file $HOME/.env/
        fi        
    done

    if [ -f /mnt/$CREDROOTFOLDER/ssh/${n}_authorized_keys ]; then
        sudo cp /mnt/$CREDROOTFOLDER/ssh/${n}_authorized_keys $HOME/.ssh/authorized_keys
    elif [ -f /mnt/$CREDROOTFOLDER/${n}/authorized_keys ]; then
            sudo cp /mnt/$CREDROOTFOLDER/${n}/authorized_keys $HOME/.ssh/authorized_keys
    else
        if [ -f /mnt/$CREDROOTFOLDER/ssh/authorized_keys ]; then
            sudo cp /mnt/$CREDROOTFOLDER/ssh/authorized_keys $HOME/.ssh/authorized_keys
        elif [ -f /mnt/$CREDROOTFOLDER/authorized_keys ]; then
            sudo cp /mnt/$CREDROOTFOLDER/authorized_keys $HOME/.ssh/authorized_keys
        fi
    fi
}

sed -i "" 's/PasswordAuthentication no/PasswordAuthentication yes/y' /etc/ssh/sshd_config

# if [ -f users.txt ]; then
#     cat users.txt >> $userfile
# fi

for n in `cat $userfile`; do
    if [ ! -d "/home/$n" ]; then
	
        echo "user $n does not exist .. creating it"
        
        sudo adduser $n
        sudo sh -c "echo '$n' | passwd --stdin $n"
        sudo mkdir -p /home/$n/.ssh
        sudo touch /home/$n/.ssh/authorized_keys
        
        sudo usermod -aG ${homeUser} $n
        #add to docker group
        if command -v docker >/dev/null; then
	    usermod -a -G docker $n
        fi
        
        #cat root bashrc to user bashrc
        sudo cat /root/.bashrc >> /home/$n/.bashrc
        
    else
        echo "user $n exists ..  passing to the folder check"    	
    fi

    #from mounted disk copy and create
    if [ -d "/mnt/$BUCKET" ]; then
        copy_user_creds $n
    fi    
    if [ ! -d "/mnt/$NOTEBOOKFOLDER/$n" ]; then
        mkdir "/mnt/$NOTEBOOKFOLDER/$n"
    fi    
    sudo chmod 600 /home/$n/.ssh/authorized_keys || echo "~/.ssh/authorized_keys does not exist"
    
    sudo chown -R $n:$n /home/$n
    
done

