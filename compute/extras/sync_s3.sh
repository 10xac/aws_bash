if [ $# -gt 0 ]; then
    msg=$1
else
    msg='minor update'
fi

git add -u *
git commit -m "$msg"
git pull
git push

folder="emr_cluster_setup"
local_folder="../$folder"
remote_path="s3://ml-box-data/$folder"

echo "Which files are most recent? Select the number"
select yn in "local" "s3"; do
    case $yn in
        local* )
	    echo "sync local to s3 folder .. ";
	    aws s3 sync --exclude="*~" --exclude="*#" ${local_folder} ${remote_path} --profile adludio;
	    break;; 
        s3* )
	    echo "to sync s3 to local, use..";
	    aws s3 sync --exclude="*~" --exclude="*#" ${remote_path} ${local_folder} --profile adludio;
	    break;;
	* ) echo "Action not found for: $yn";
    esac
done
