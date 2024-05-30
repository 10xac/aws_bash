pexist=
if [ -f ~/.aws/config ]; then
    pexist=$(grep tenac ~/.aws/config)
fi


function get_aws_profile() {
    region=${1:-"us-east-1"}
    if [ ! -z ${pexist} ]; then
	prof="--profile kifiya --region $region"
	if [ ! -z $profile_name ]; then prof="--profile $profile_name --region $region"; fi
    else
	prof="--region $region"
    fi
    echo $prof
}

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
    #--require-each-included-type \    
    res=$(aws secretsmanager get-random-password \
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

function get_api_key(){
    # app_key salt
    e=${1:-"dev"}
    key=${2:-"API_KEY"}
    ssmappkey="${e}/csengine-api-key"
    appkey=$(get_ssm_secret $ssmappkey)
    if [ -z $appkey ]; then
	echo "Generating Random APP_KEY and saving it in AWS secret manager"
	appkey=$(gen_ssm_secret 20)
        string="{\"$key\":\"$appkey\"}"
	save_ssm_secret $string $ssmappkey
    fi
    echo ""
    echo "{\"$key\":\"$appkey\"}"
    echo ""
}


curdir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
efs_path="/mnt/efs/ec2monitor"

#determine rootdir for env and cred files
if [ ! -d ${efs_path} ]; then
    rootdir=$(dirname $curdir)
else
    rootdir=${efs_path}
fi

envdir=$rootdir/.env
mkdir -p $envdir

#fastapi vars
envfile="$envdir/.envdev"
if [ ! -f $envfile ]; then
    keyname='tenx/env/vars'
    region="us-east-1"
    prof=$(get_aws_profile $region)
    echo "using prof=$prof .."
    
    echo "reading $keyname from AWS SM .."
    res=$(get_ssm_secret $keyname)
    
    echo $res > temp.json
    res=$(jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' temp.json)
    rm temp.json
    for x in $res; do
        echo "$x" >> $envfile
        export $x
    done
    echo "secret saved to ${envfile}"
else
    echo "using existing ${envfile}"
fi


#echo "===============cat ${envfile}============"
#cat $envfile
#echo "========================================="

#kedro creds
mkdir -p ${rootdir}/conf/local

credfile="${rootdir}/conf/local/credentials.yaml"
if [ ! -f $credfile ]; then

    echo "saving kedro cred to $credfile"
    cat <<EOF > $credfile
db_dev_almlabler:
    con: "${PGDB_CON_TENX_DEV}/almlabler"
db_dev_strapidev:
    con: "${PGDB_CON_TENX_DEV}/strapidev"
db_prod_strapiprod:
    con: "${PGDB_CON_TENX_PROD}/strapiprod"
db_dev_applyprod:
    con: "${PGDB_CON_APPLY}/applyprod"
db_dev_applydev:
    con: "${PGDB_CON_APPLY}/applydev"
db_dev_applydev:
    con: "${PGDB_CON_APPLY}/applydev"

weaviate_credentials:
    url: ${WEAVIATE_URL}
    api_key: ${WEAVIATE_API_KEY}

EOF
    
else
    echo "using exiting $credfile"
fi
#echo "===============cat ${credfile}============"
#cat $credfile
#echo "========================================="
