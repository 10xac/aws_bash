#Reference
#https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-s3fs




scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}

echo "mounts3: home=$home"
echo "BUCKET=$BUCKET"
source $home/.bashrc
BUCKET="${BUCKET:-10ac-batch-4}"


if [ -d $home ]; then
    homeUser=$(basename $home)
else
    homeUser=`whoami`
fi
echo "BUCKET=$BUCKET"


#check bucket exists else create it
aws s3api head-bucket --bucket $BUCKET  || not_exist=true
if [ $not_exist ]; then
    #aws s3 mb BUCKET
    echo "$BUCKET does NOT exist - aborting mount!"    
    exit 0
else
  echo "$BUCKET exists!"
fi

# -----------------------------------------------------------------------------
# 7. install dependencies for s3fs-fuse to access and store notebooks
#    install emacs as well
# -----------------------------------------------------------------------------
function install_s3fs()
{

    if command -v conda >/dev/null; then
	conda install -c conda-forge s3fs-fuse	
	exit
	
    elif command -v apt-get >/dev/null; then
        sudo apt-get remove -y fuse
	#sudo apt-get install -y gcc gcc-c++ autotools-dev automake 
	#sudo apt-get install -y openssl-devel libcurl libssl1.0.0 libssl-dev libxml-2.0 fuse 
        #sudo apt-get install -y build-essential libcurl4-openssl-dev libxml2-dev mime-support

	sudo apt-get install -y build-essential git libfuse-dev libcurl4-openssl-dev libxml2-dev mime-support automake libtool
	sudo apt-get install -y pkg-config libssl-dev # See (*3)

	sudo apt-get install -y memcached
	sudo service memcached start	

	
    elif command -v yum >/dev/null; then
	sudo yum install -y gcc gcc-c++	
	sudo yum install -y openssl-devel libcurl libcrypto.so.10 libxml-2.0 fuse autotools-dev 
	sudo yum install -y libcurl libcurl-devel graphviz cyrus-sasl cyrus-sasl-devel readline readline-devel gnuplot
	sudo yum install -y automake fuse fuse-devel libxml2-devel
	sudo yum install -y memcached 
	sudo yum install -y automake
	sudo service memcached start
	
    else
	echo "unknown os system.."
	exit
    fi    
    
    git clone https://github.com/s3fs-fuse/s3fs-fuse.git
    cd s3fs-fuse/
    ls -alrt
    ./autogen.sh
    ./configure --prefix=/usr/local --with-openssl
    make
    sudo make install
    
}

if [ $# -gt 0 ]; then
    if [ $1 == "unmount" ]; then	
	#https://stackoverflow.com/questions/24966676/transport-endpoint-is-not-connected
	#https://dausruddin.com/fusermount-failed-to-unmount-path-device-or-resource-busy/
	#sudo /usr/local/bin/fusermount -uz /mnt/$BUCKET
	sudo umount -l /mnt/$BUCKET
	pkill  s3fs
    else
	install_s3fs
    fi
else
    echo "assuming s3fs and other necessary files installed already .."
    echo ""
fi

if [ $# -gt 1 ]; then
    if [ $1 == "unmount" ]; then
        if [ $2 != "mount" ]; then
            exit 0
        fi
    fi
fi

#mount s3 bucket
if [ -f ${HOME}/.passwd-s3fs ]; then
    pval="passwd_file=${HOME}/.passwd-s3fs"
else
    pval="iam_role=auto"
fi

if [ -f /usr/local/bin/s3fs ]; then
    sudo su -c 'echo user_allow_other >> /etc/fuse.conf'
    mkdir -p /mnt/s3fs-cache
    mkdir -p /mnt/$BUCKET
fi

/usr/local/bin/s3fs $BUCKET /mnt/$BUCKET -o allow_other -o $pval \
	      -o umask=0 -o url=https://s3.amazonaws.com  -o no_check_certificate \
	      -o cipher_suites=AESGCM \
	      -o max_background=1000 \
	      -o max_stat_cache_size=100000 \
	      -o multipart_size=52 \
	      -o parallel_count=30 \
	      -o multireq_max=30 \
	      -o dbglevel=warn \
	      -o enable_noobj_cache -o use_cache=/mnt/s3fs-cache

echo "mounting $BUCKET done"
#-o kernel_cache 

#sudo chmod 777 -R /mnt || echo "unable to change /mnt permission"
#sudo chown $homeUser:$homeUser -R /mnt || echo "unable to change /mnt ownership"
