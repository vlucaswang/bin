#!/bin/bash

#Tranfer SCRCU ftp files to sub-urban ftp
#Provided by Xiaochuan Wang
#xiaochuan.wang@sysssc.com

STARTTIME=$(date +%s)
ROOT_UID=0
FTPBASE=/data/rpt

#Run as root.
if  [ "$EUID" -ne "$ROOT_UID" ];then
	echo "Must be root to run this script."
	exit 87
fi

#Need two parameters.
#if [ $# != 1 ];then
#    echo "Usage: $0 {file path}" >&2
#    exit 1
#fi

#IPFILE=$(cat $1 | grep -v '^#' $1)

while read line; do
	CC=$(echo $line | cut -d ":" -f1)
	IP=$(echo $line | cut -d ":" -f2)
	rsync -az --delete $FTPBASE/LS/$CC $IP:$FTPBASE/LS/ > /dev/null 2>&1
	rsync -az --delete $FTPBASE/WD/$CC $IP:$FTPBASE/WD/ > /dev/null 2>&1
#	tar -C $FTPBASE/LS/$CC -jcf - ./ | ssh $IP 'tar -C $FTPBASE/LS/$CC -jxf -'
#	tar -C $FTPBASE/WD/$CC -jcf - ./ | ssh $IP 'tar -C $FTPBASE/WD/$CC -jxf -'
	ssh -n $IP "chown ftphost.ftphost -R $FTPBASE"
	echo "Sub Center $CC completed."
#done < $1
done < 1.txt

ENDTIME=$(date +%s)
DIFFTIME=$(( $ENDTIME - $STARTTIME ))
echo "It took $DIFFTIME seconds."

exit 0