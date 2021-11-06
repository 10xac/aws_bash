home=$HOME

if command -v apt-get >/dev/null; then
    if [ -d /home/ubuntu ]; then
        home=/home/ubuntu
    fi
else
    if [ -d /home/centos ]; then
        home=/home/centos
    fi
    if [ -d /home/ec2-user ]; then
        home=/home/ec2-user
    fi
    if [ -d /home/hadoop ]; then
        home=/home/hadoop
    fi    
fi

echo $home
