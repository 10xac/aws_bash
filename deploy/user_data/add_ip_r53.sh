
#------------START: code to build from git------------
if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<EOF >>  $fout

region=${region:-"eu-west-1"}
r53dns=$dns_namespace
hosted_zone_id=${hosted_zone_id:-Z034028834IXN0CQEMHZ9}

EOF


cat <<'EOF' >>  $fout

# add public id to route 53
publicip=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)


#http://www.scalingbits.com/aws/dnsfailover/changehostnameentries

frecord="r53_record.json"
cat <<EOF > $frecord
{
  "Comment": "CREATE/UPDATE a record ",
  "Changes": [{
  "Action": "UPSERT",
              "ResourceRecordSet": {
                  "Name": "$r53dns",
                  "Type": "A",
                  "TTL": 60,
              "ResourceRecords": [{ "Value": "$publicip"}]

              }
  }]
}


#----------------------------------------#
###-------- Create a record set---------##
##---------------------------------------#

export AWS_PAGER=""

aws route53 change-resource-record-sets \
    --hosted-zone-id ${hosted_zone_id} \
    --change-batch file://$frecord \
    --region $region


EOF


