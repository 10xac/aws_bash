
region=${region:-"eu-west-1"}
ssmgittoken=${ssmgittoken:-"git_token_tenx"}
gituname=${gituname:-"10xac"}
repo_name=${repo_name:-""}

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
