MASTER_KV=$(grep masterHost /emr/instance-controller/lib/info/job-flow-state.txt)
MASTER_HOST=$(ruby -e "puts '$MASTER_KV'.gsub('\"','').split.last")
echo "Master IP: ${MASTER_HOST}"

echo "Master IP: $(hostname -f)"
echo "List of the ip addresses of emr slave nodes:"
yarn node -list 2>/dev/null | sed -n "s/^\(ip[^:]*\):.*/\1/p"
