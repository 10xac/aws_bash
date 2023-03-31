set -e

export AWS_PAGER=""

#-------------------------------------------------------------------------
#             process input arguments
#-------------------------------------------------------------------------

echo "Number passed arguments: $#"
if [ $# -gt 0 ]; then
   source $1
else
    echo "You must pass the following"
    echo "     1st argument - a configuration file: that contains key parameters"
    echo "     2nd argument - action: status or iplink  "
    exit 0
fi


profile_name=${profile_name:-$profile}
region=${region:-"eu-west-1"}
prof="--region $region --profile $profile_name"

function get_ssm_secret() {
	#echo "reading key=$1 from aws secret manager"
	res=$(aws secretsmanager get-secret-value \
       	       --secret-id $1  \
	       --query SecretString \
               --output text $prof || echo "")
	echo $res
}
function gen_ssm_secret() {
	#echo "generating random password from aws secret manager"
	res=$(aws secretsmanager get-random-password \
	       #--require-each-included-type \
		--exclude-punctuation \
	       --password-length ${1:-20} $prof | jq -r '.RandomPassword')
	echo $res
}
function save_ssm_secret() {
	echo "saving key=$2, value=$1 to aws secret manager"
	res=$(aws secretsmanager create-secret  \
		    --name $2  \
		    --secret-string $1 $prof)
}



gittoken=$(get_ssm_secret $ssmgittoken)
if [ -z $gittoken ]; then
    echo "storing gittoken to secret manager ..."
    if [ -z $GIT_PAT_YABI ]; then
        read -p 'Please provide GIT TOKEN to save to AWS secret manager: ' gittoken
    else
        gittoken=$GIT_PAT_YABI
    fi
    #read -sp 'Password: ' passvar
    echo    
    save_ssm_secret $gittoken $ssmgittoken        
    echo "... done saving $gittoken as GIT TOKEN!"
fi

