##------------------------------------------------------#
###-----Define necessary environment variables if passed -----##
##------------------------------------------------------#
if [ ! -z "$1" ]; then            
    echo "Loading variables from $1"
    source $1 #many key variables returned
    source create_conflog_dir.sh ""
    echo "confdir=$configoutputdir"
    echo "logdir=$logoutputdir"    
fi


#---------------------------------------------------------#
### ----------- Change dir to output of the project------##
##-------------------------------------------------------#


echo ${git_token}
region="eu-west-1"
git_token=$(aws secretsmanager get-secret-value \
    --secret-id ${ssmgittoken} \
    --query SecretString \
    --output text --region $region  | cut -d: -f2 | tr -d \"})
                                                              
                                                              
#echo ${git_token}

cd $logoutputdir

#---------------------------------------------------------#
### ----------- Clone the repository---------------------##
##-------------------------------------------------------#
git clone https://${git_token}@github.com/${gituname}/${repo_name}


#---------------------------------------------------------#
### ----------- Push the config file to the repository---##
##-------------------------------------------------------#
if $github_actions; then
    echo "---------copying github actions config file to repo ...."
    folder=".github/workflow"
    conffile="github_actions_config.yml"
    basename="main"
else
    echo "---------copying circleci config file to repo ...."    
    folder=".circleci"
    conffile="circleci_config.yml"
    basename="config"
fi

mkdir -p ${repo_name}/${folder}
cp configs/$conffile ${repo_name}/${folder}/$basename{}.yml
cd ${repo_name}
git add $folder
git commit -m "added $conffile config"
git push 


#---------------------------------------------------------#
##------------- Remove the cloned repository-------------##
##-------------------------------------------------------#
rm -r ../${repo_name} --force
