batch=6  #${$1:-6}
for i in 1 2 3 4 5; do
    cut -d "," -f 1 compute/user/b${batch}g${i}.txt || echo "group compute/user/b${batch}g${i}.txt does not exist"
done
