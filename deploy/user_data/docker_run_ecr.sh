if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<EOF >>  $fout


aws ecr get-login-password \
    --region ${region} \
| docker login \
    --username AWS \
    --password-stdin 070096167435.dkr.ecr.${region}.amazonaws.com
docker pull $ecrimage

docker run $dockerenv -d $ecrimage

EOF
