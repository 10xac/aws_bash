scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
maindir=$(dirname $scriptDir)

home=${ADMIN_HOME:-$(bash get_home.sh)}

if [ -d $home ]; then
    homeUser=$(basename $home)
else
    homeUser=`whoami`
fi

echo "setting up cron jobs to restart background services .. "

#mount s3 folder
if ${mounts3:-true}; then
    echo "       > mount s3 bucket ..."
    (crontab -l 2>/dev/null; echo "@reboot  sudo /bin/bash ${maindir}/s3mount/mount-s3fs.sh") | crontab -
fi

#add jupyterhub restart if required
if ${setupjhub:-false}; then
    echo "       > restart jupyterhub service .."
    (crontab -l 2>/dev/null; echo "@reboot  sudo systemctl restart jupyterhub") | crontab -
fi


