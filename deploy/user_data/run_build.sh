
#------------START: code to build from git------------
if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<EOF >>  $fout

region=${region:-"eu-west-1"}
ssmgittoken=${ssmgittoken:-"git_token_tenx"}
gituname=${gituname:-"10xac"}
repo_name=${repo_name:-""}

EOF

#write the code that needs to be expanded in remote env here
cat <<'EOF' >>  $fout

if [ ! -z $repo_name ]; then

    git_token=$(aws secretsmanager get-secret-value \
                    --secret-id ${ssmgittoken} \
                    --query SecretString \
                    --output text --region $region  | cut -d: -f2 | tr -d \"})

  #----------------------
  cd ${home:-$HOME}
  
  git clone https://${git_token}@github.com/${gituname}/${repo_name}

  cd $repo_name
  if [ -f build.sh ]; then
      bash build.sh
  fi
fi                                  

EOF
#------------START: code to build from git------------
