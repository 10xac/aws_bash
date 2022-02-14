status="$(systemctl is-active jupyterhub)"
if [ ! "${status}" = "active" ]; then
    sudo sh -c "systemctl start jupyterhub"
fi


if [ ! -d "/mnt/$BUCKET" ]; then
    sudo sh -c "bash scripts/s3mount/mount-s3fs.sh install"
fi
