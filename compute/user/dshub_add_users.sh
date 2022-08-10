scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}

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
    echo "copy user ssh key to /home/$n/.ssh/authorized_keys"
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
        echo "copy ssh key from /mnt/$CREDROOTFOLDER/ssh/${n}_* .."
        cp /mnt/$CREDROOTFOLDER/ssh/${n}_authorized_keys $HOME/.ssh/authorized_keys
    elif [ -f /mnt/$CREDROOTFOLDER/${n}/authorized_keys ]; then
        echo "copy from /mnt/$CREDROOTFOLDER/${n} .."
        cp /mnt/$CREDROOTFOLDER/${n}/authorized_keys $HOME/.ssh/authorized_keys
    else
        echo "WARNING:/mnt/$CREDROOTFOLDER/ssh/${n}_* or /mnt/$CREDROOTFOLDER/${n}/* NOT FOUND!! USING GENERIC PUBLIC KEY"
        if [ -f /mnt/$CREDROOTFOLDER/ssh/authorized_keys ]; then
            echo "copy from /mnt/$CREDROOTFOLDER/ssh/authorized_keys .."
            cp /mnt/$CREDROOTFOLDER/ssh/authorized_keys $HOME/.ssh/authorized_keys
        elif [ -f /mnt/$CREDROOTFOLDER/authorized_keys ]; then
            echo "copy from /mnt/$CREDROOTFOLDER/authorized_keys .."
            cp /mnt/$CREDROOTFOLDER/authorized_keys $HOME/.ssh/authorized_keys
        fi
    fi
}

function allow_user_sudo() {
    grps=$(groups ${homeUser} | cut -d" " -f 4- | tr ' ' ',')
    usermod -aG ${grps} $1
    echo "user=$1 added to groups: $grps"
}

#sed -i "" 's/PasswordAuthentication no/PasswordAuthentication yes/y' /etc/ssh/sshd_config

# if [ -f users.txt ]; then
#     cat users.txt >> $userfile
# fi

cat $userfile | while read line; do
    
    IFS=', ' read -r -a array <<< "$line"
    n="${array[0]}"
    nflag="${array[1]}"
    if [ -z $n ]; then
        continue
    fi
    echo ""
    echo "---------processing line: $line ---------"
    echo ""
    
    
    if [ ! -d "/home/$n" ]; then
	
        echo "user $n does not exist .. creating it"

        #https://www.baeldung.com/linux/passwd-shell-script
        #https://askubuntu.com/questions/94060/run-adduser-non-interactively
        
        p=$(python3 -c 'import crypt; print(crypt.crypt("$n"))')
        useradd -m -p $p -s /bin/bash $n

        #echo "$n:$n" | chpasswd
        
        # adduser $n
        # sh -c "echo '$n' | passwd --stdin $n"
        
        mkdir -p /home/$n/.ssh
        touch /home/$n/.ssh/authorized_keys

        
        #add to docker group
        if command -v docker >/dev/null; then
	    usermod -a -G docker $n
        fi
        
        #cat root bashrc to user bashrc
        cat /root/.bashrc >> /home/$n/.bashrc
        
    else
        echo "user $n exists ..  passing to the folder check"    	
    fi

    # specified to have root access - allow sudo
    if [ "$nflag" == "root" ]; then
        allow_user_sudo $n
    fi
    
    #from mounted disk copy and create
    if [ -d "/mnt/$BUCKET" ]; then
        copy_user_creds $n
    fi
    
    if [ ! -d "/mnt/$NOTEBOOKFOLDER/$n" ]; then
        mkdir "/mnt/$NOTEBOOKFOLDER/$n"
    fi

    if [ -f "/home/$n/.ssh/authorized_keys" ]; then
        chmod 600 /home/$n/.ssh/authorized_keys || echo "~/.ssh/authorized_keys does not exist"
    fi

    if [ -d "/home/$n" ]; then
        chown -R $n:$n /home/$n
    fi
done

