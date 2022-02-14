configfile="./variables.txt"
[ $# -gt 0 ] && [ -r "$1" ] && configfile="$1"

sed -e 's/[[:space:]]*#.*// ; /^[[:space:]]*$/d' "$configfile" |
    while read line; do
	echo "export $line" #>> ~/.bashrc                                                                                                
    done
