
#------------START: code to build from git------------
if [ -z "$1" ]; then
    echo "user_data: path to file to append user data must be passed!"
    exit 1
else
    fout=$1
fi

cat <<EOF >>  $fout

sysctl vm.overcommit_memory=1 || echo "not able to set vm.overcommit_memory=1"
echo never > /sys/kernel/mm/transparent_hugepage/enabled || echo "not able to put never to /sys/kernel/mm/transparent_hugepage/enabled"

EOF
