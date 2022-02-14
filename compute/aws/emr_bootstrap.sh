#!/bin/bash

#reference for user_data script
#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

folder="emr_cluster_setup"
fpath="s3://ml-box-data/${folder}"

#copy scripts
aws s3 cp $fpath ${HOME}/$folder --recursive || echo "failed to excute: aws s3 cp $fpath ${HOME}/$folder"

echo "folder=${HOME}/$folder"
echo "$folder files: "
ls ${HOME}/${folder} | echo "failed to list: ${HOME}/$folder"

#change dir
cd ${HOME}/${folder} | echo "failed to cd to: ${HOME}/$folder "
/bin/bash ${HOME}/${folder}/new_machine_setup.sh | echo "failed to excute: /bin/bash new_machine_setup.sh"
