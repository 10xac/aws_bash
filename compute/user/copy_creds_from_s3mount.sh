#copy creds
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cdir=$(dirname $scriptDir)
home=${ADMIN_HOME:-$(bash $cdir/get_home.sh)}


BUCKET="${BUCKET:-ml-box-data}"
CREDROOTFOLDER="${CRED_ROOT_FOLDER:-/mnt/$BUCKET/creds}"
CREDFOLDERS="${CRED_FOLDERS:-aws adludio}"
CREDENVFILES="${CRED_ENV_FILES:-}" 

for folder in $CREDFOLDERS; do        
    if [ -d $CREDROOTFOLDER/$folder ]; then
        mkdir $home/.$folder || echo "~/.$folder exists"        
        cp -r $CREDROOTFOLDER/$folder/* $HOME/.$folder/
    fi    
done

for file in $CREDENVFILES; do        
    if [ -d $CREDROOTFOLDER/$file ]; then
        mkdir $home/.env || echo "~/.$folder exists"        
        cp -r $CREDROOTFOLDER/$file $HOME/.env/
    fi        
done
