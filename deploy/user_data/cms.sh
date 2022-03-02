
region=${region:-"eu-west-1"}
ssmgittoken=${ssmgittoken:-"git_token_tenx"}
gituname=${gituname:-"10xac"}
        }
git_token=$(aws secretsmanager get-secret-value \
    --secret-id ${ssmgittoken} \
    --query SecretString \
    --output text --region $region  | cut -d: -f2 | tr -d \"})
                                                              
git clone https://${git_token}@github.com/${gituname}/tenx-cms

cd tenx-cms
bash update.sh

                                                              
