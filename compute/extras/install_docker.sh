scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
maindir=$(dirname $scriptDir)

home=${ADMIN_HOME:-$(bash $maindir/get_home.sh)}
if [ -d $home ]; then
    homeUser=$home
else
    homeUser=`whoami`
fi
if command -v docker >/dev/null; then
	echo "docker is already installed"
else
    if [ -f /usr/local/bin/docker ]; then
	echo "adding /usr/local/bin in PATH as docker is already installed there"
	echo "Consider sourcing ~/.bashrc in your shell"
	echo "export PATH=/usr/local/bin:$PATH" >> ~/.bashrc
	source ~/.bashrc
    else    
	echo "installing docker .."
	if command -v apt-get >/dev/null; then
            sudo apt update
            sudo apt upgrade -y
            sudo apt install apt-transport-https ca-certificates curl software-properties-common -y

            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

            sudo apt update
            sudo apt install docker-ce -y
            
	    sudo service docker start
	    sudo usermod -a -G docker ${homeUser}
	    
	elif command -v yum >/dev/null; then
	    sudo yum update -y
	    sudo yum install -y docker
	    sudo service docker start
	    sudo usermod -a -G docker ${homeUser}
	else
	    echo "unknown os system.."
	    exit
	fi
    fi
fi

if command -v docker-compose >/dev/null; then
	echo "docker-compose is already installed"
else
    if [ -f /usr/local/bin/docker-compose ]; then
	echo "adding /usr/local/bin in PATH as docker-compose is already installed there"
	echo "Consider sourcing ~/.bashrc in your shell"
	echo "export PATH=/usr/local/bin:$PATH" >> ~/.bashrc
	source ~/.bashrc
    else
	echo "installing docker-compose .."	
	sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
    fi
fi

docker --version
docker-compose --version

if [ -f $1 ]; then
    userfile=$1

    sudo groupadd docker || echo "docker user already exists"

    for n in `cat $userfile`; do
	if [ -d "/home/$n" ]; then
            echo "adding user=$n to docker group .."
            sudo usermod -aG docker $n || echo "user $n already in docker group"
	fi
    done
    sudo systemctl restart docker
    sudo systemctl restart containerd
    
fi
