scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}


create_mem_limited_sys_users() {
    #Ref
    #https://www.thegeekdiary.com/how-to-limit-some-user-memory-resources-on-centos-rhel-using-cgroup/
    if [ $# -gt 0 ]; then
        sysusers=$1
    else
        exit 0
    fi

    meminbyte=20485760000    
    #create cgroup called memlimit where limit is 16gb
    sudo echo "group memlimit {" >> /etc/cgconfig.conf
    sudo echo "memory {" >> /etc/cgconfig.conf
    sudo echo "memory.limit_in_bytes = ${meminbyte};" >> /etc/cgconfig.conf
    sudo echo "}" >> /etc/cgconfig.conf
    sudo echo "}" >> /etc/cgconfig.conf
    
    
    for u in $sysusers; do
        #create new user
        sudo adduser $u
        sudo sh -c "echo '$u' | passwd --stdin $n"
        sudo mkdir -p /home/$u/.ssh
        sudo chmod 700 /home/$u/.ssh
        sudo touch /home/$u/.ssh/authorized_keys || true
        sudo chmod 600 /home/$u/.ssh/authorized_keys || true
        #sudo cp -r ~/creds/.a* /home/$n/
        sudo chown -R $u:$u /home/$u || true
        
        #
        #tell cgroups that user testme will be added to memlimit cgroup             
        sudo echo "$u memory memlimit/" >> /etc/cgrules.conf
    done
    
    #start cgred/cgconfig and make sure that they will also start on boot of the system
    sudo service cgred restart || true
    sudo service cgconfig restart || true
    sudo chkconfig cgred on || true
    sudo chkconfig cgconfig on | true
}

apply_mem_limit() {
    if [ $# -gt 0 ]; then
        sysusers=$1
    else
        exit 0
    fi

    meminbyte=24485760000
    #create cgroup called memlimit where limit is 16gb
    sudo sh -c "echo 'group memlimit {' >> /etc/cgconfig.conf"
    sudo sh -c "echo 'memory {' >> /etc/cgconfig.conf"
    sudo sh -c "echo 'memory.limit_in_bytes = $meminbyte;' >> /etc/cgconfig.conf"
    sudo sh -c "echo '}' >> /etc/cgconfig.conf"
    sudo sh -c "echo '}' >> /etc/cgconfig.conf"

    for u in `cat $sysusers`; do
	echo "applying memlimit (byte)=$meminbyte for user: $u"
	#tell cgroups that user testme will be added to memlimit cgroup             
	sudo sh -c "echo '$u memory memlimit/' >> /etc/cgrules.conf"
    done
    
    #start cgred/cgconfig and make sure that they will also start on boot of the system
    sudo service cgred restart || true
    sudo service cgconfig restart || true
    sudo chkconfig cgred on || true
    sudo chkconfig cgconfig on | true    
}

if [ $# -gt 0 ]; then
    userfile=$1
else
    userfile="users.txt"
fi

apply_mem_limit $userfile
