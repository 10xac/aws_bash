curdir=`pwd`

folder=${1:-"deploy"}
opt=${2:-''}
if [ -z $opt ]; then
    optTxt='Non-Dry-Run (actual sync) '
else
    optTxt='Dry-Run (no sync)'
fi

if [[ "$curdir" == *"Adludio"* ]]; then
    echo "$optTxt: sync code from adludio aws_bash to 10 academy"
    rsync *.sh ~/My-Works/10academy/Codes/aws_bash/
    rsync deploy/configs/ec?_params.sh ~/My-Works/10academy/Codes/aws_bash/deploy/configs/
    
    
    if [ $folder == "deploy" ]; then
        rsync -av$opt --exclude="*.txt" \
              --exclude="configs" \
              --exclude="output" \
              --exclude="apps" \
              deploy/ ~/My-Works/10academy/Codes/aws_bash/deploy
    fi
    #
    if [ $folder == "compute" ]; then
        rsync -av$opt --exclude="*.txt" \
              --exclude="configs" \
              --exclude="output" \
              --exclude="apps" \
              --exclude="w?/" \
              compute/ ~/My-Works/10academy/Codes/aws_bash/compute    
    fi
    #rsync deploy/*.sh ~/My-Works/10academy/Codes/aws_bash/compute/
    #rsync deploy/user_data/*.sh ~/My-Works/10academy/Codes/aws_bash/deploy/user_data/
    
fi

if [[ "$curdir" == *"10academy"* ]]; then
    echo "$optTxt: sync code from 10academy aws_bash to adludio"    
    rsync *.sh ~/My-Works/Adludio/aws_bash/
    rsync deploy/configs/ec?_params.sh ~/My-Works/Adludio/aws_bash/deploy/configs/
    
    if [ $folder == "deploy" ]; then
        rsync -av$opt --exclude="*.txt" \
              --exclude="configs" \
              --exclude="output" \
              --exclude="apps" \
              deploy/ ~/My-Works/Adludio/aws_bash/deploy
    fi
    #
    if [ $folder == "compute" ]; then
        rsync -av$opt --exclude="*.txt" \
              --exclude="configs" \
              --exclude="output" \
              --exclude="apps" \
              --exclude="w?/" \
              compute/ ~/My-Works/Adludio/aws_bash/compute    
    fi
    #rsync deploy/*.sh ~/My-Works/Adludio/aws_bash/deploy/
    #rsync deploy/user_data/*.sh ~/My-Works/Adludio/aws_bash/deploy/user_data/
    
fi
