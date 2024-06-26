#Reference
#https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-s3fs

if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<'EOF' >>  $fout

if [ -d /home/ubuntu/s3mount.sh ]; then
   echo ""
   echo "============================================"
   echo "           Run home/ubuntu/s3mount        "
   echo "============================================"
   echo ""

   bash  /home/ubuntu/s3mount.sh

else

EOF
cat <<EOF >>  $fout

BUCKET="${s3bucket:-BUCKET}"

echo ""
echo "============================================"
echo "           Mount S3 Bucket=${BUCKET}                  "
echo "============================================"
echo ""


EOF

#write the code that needs to be expanded in remote env here
cat <<'EOF' >>  $fout

# remove s3:// from bucket 
BUCKET=${BUCKET#"s3://"}  #remove s3://
BUCKET=${BUCKET%/}  #remove training /

# write mount unmount script 
cat <<EOFF >>  $home/s3mount.sh

echo "BUCKET=$BUCKET"


#check bucket exists else create it
aws s3api head-bucket --bucket $BUCKET  || not_exist=true
if [ $not_exist ]; then
    aws s3 mb BUCKET
    echo "$BUCKET does NOT exist - created new to mount!"    
    #exit 0
else
  echo "$BUCKET exists!"
fi

# -----------------------------------------------------------------------------
# 7. install dependencies for s3fs-fuse to access and store notebooks
#    install emacs as well
# -----------------------------------------------------------------------------
function install_s3fs()
{

    if command -v apt-get >/dev/null; then
        apt-get -qq remove -y fuse
	apt-get -qq install -y gcc gcc-c++
	apt-get -qq install -y openssl-devel libcurl libssl1.0.0 libssl-dev libxml-2.0 fuse automake
        apt-get -qq install -y build-essential libcurl4-openssl-dev libxml2-dev mime-support        
        
    elif command -v yum >/dev/null; then
	yum -qq install -y gcc gcc-c++	
	yum -qq install -y openssl-devel libcurl libcrypto.so.10 libxml-2.0 fuse automake	
	yum -qq install -y libcurl libcurl-devel graphviz cyrus-sasl cyrus-sasl-devel readline readline-devel gnuplot
	yum -qq install -y automake fuse fuse-devel libxml2-devel
    else
	echo "unknown os system.."
	exit
    fi    


    # install s3fs
    if command -v apt-get >/dev/null; then
        echo "Installing s3fs using apt..."
        apt -qq install -y s3fs
    elif command -v yum >/dev/null; then
        echo "Installing s3fs using yum..."
        amazon-linux-extras install epel || echo "not in aws linux"
        yum -qq install -y s3fs-fuse
    else
        echo "Installing s3fs from source..."
        git clone https://github.com/s3fs-fuse/s3fs-fuse.git
        cd s3fs-fuse/
        ls -alrt
        ./autogen.sh
        ./configure #–prefix=/usr/local
        make
        make install
        su -c 'echo user_allow_other >> /etc/fuse.conf'
    fi
}

if command -v s3fs >/dev/null; then
    echo "s3fs and other necessary files are installed already .."
    echo ""
else
    if [ "$1" == "unmount" ]; then	
	#https://stackoverflow.com/questions/24966676/transport-endpoint-is-not-connected
	#https://dausruddin.com/fusermount-failed-to-unmount-path-device-or-resource-busy/
	fusermount -uz /mnt/$BUCKET
	umount -l /mnt/$BUCKET
	pkill  s3fs
    else
	install_s3fs
    fi
fi

mkdir -p /mnt/s3fs-cache
mkdir -p /mnt/$BUCKET

# mount s3 bucket
# https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-s3fs
s3fs $BUCKET /mnt/$BUCKET -o allow_other -o iam_role=auto \
-o umask=0 -o url=https://s3.amazonaws.com  -o no_check_certificate \
-o cipher_suites=AESGCM \
-o max_background=1000 \
-o max_stat_cache_size=100000 \
-o multipart_size=52 \
-o parallel_count=30 \
-o multireq_max=30 \
-o dbglevel=warn \
-o enable_noobj_cache -o use_cache=/mnt/s3fs-cache 

EOFF

echo "Mounting $BUCKET to /mnt/$BUCKET"
source $home/s3mount.sh install

echo "Files in /mnt/$BUCKET : "
ls /mnt/$BUCKET


DIR_PATH=$(cd $(dirname “${BASH_SOURCE:-$0}”) && pwd)
scriptpath=$DIR_PATH/$(basename “${BASH_SOURCE:-$0}”)

echo " adding $scriptpath to crontab .."
(crontab -l 2>/dev/null; echo "@reboot  BUCKET=$BUCKET /bin/bash ${scriptpath}") | crontab -

fi

EOF
