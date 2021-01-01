SEC=5
test "$1" && SEC=$1


while true
do 
	echo sleeping for $SEC seconds
	sleep $SEC
done
