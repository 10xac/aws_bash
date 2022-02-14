#start workers in slave nodes

for ip in `yarn node -list 2>/dev/null | sed -n "s/^\(ip[^:]*\):.*/\1/p"`; do
    echo "available node with ip: $ip"    
    # echo "copying authorised_keys to node with ip: $ip"
    # ssh -i ~/.ssh/authorized_keys $ip:~/.ssh/     
done

