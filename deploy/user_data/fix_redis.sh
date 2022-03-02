sysctl vm.overcommit_memory=1 || echo "not able to set vm.overcommit_memory=1"
echo never > /sys/kernel/mm/transparent_hugepage/enabled || echo "not able to put never to /sys/kernel/mm/transparent_hugepage/enabled"
