for ig in 2 3 4 5; do

    if [ "$1" == "create" ]; then
        echo "******creating instances for group=$ig********"
        group=$ig bash ec2_compute.sh params/w7.sh 
    elif [ "$1" == "iplink" ]; then
        echo "*********updating r53 record with IP for group=$ig******"        
        group=$ig bash postup/update_r53_record.sh params/w7.sh
    else
        echo "*****unknown operation requested 1st argument=$1*****"
    fi

done
