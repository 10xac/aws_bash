curdir=`pwd`

if [[ "$curdir" == *"Adludio"* ]]; then
    echo "sync code from adludio aws_bash to 10 academy"
    rsync *.sh ~/My-Works/10academy/Codes/aws_bash/
    rsync deploy/*.sh ~/My-Works/10academy/Codes/aws_bash/deploy/
    rsync deploy/user_data/*.sh ~/My-Works/10academy/Codes/aws_bash/deploy/user_data/
fi

if [[ "$curdir" == *"10academy"* ]]; then
    echo "sync code from 10academy aws_bash to adludio"    
    rsync *.sh ~/My-Works/Adludio/aws_bash/
    rsync deploy/*.sh ~/My-Works/Adludio/aws_bash/deploy/
    rsync deploy/user_data/*.sh ~/My-Works/Adludio/aws_bash/deploy/user_data/
fi
