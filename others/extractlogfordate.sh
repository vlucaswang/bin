#!/bin/bash

Ftp_Server_Dir=$(date +%Y%m%d)
ftpaddr="ip"
ftpuser="ftpuser"
ftppass="ftppass"

#read the date for extracting log
read -p "Please input start date: " Startdate
read -p "Please input finish date: " Senddate
date1=$(date -d $Startdate "+%s")
date2=$(date -d $Senddate "+%s")
date_count=$(echo "$date2 - $date1"|bc)
day_m=$(echo "$date_count"/86400|bc)
for ((sdate=0;sdate<"$day_m";sdate++))
do
	tmp=$(date -d "$Startdate $sdate days" "+%F")
	tmp=report$tmp.log.old
	logfiles="$logfiles $tmp"
done

#the path of certain desired log
file_dir=/var/log
date=`date +%Y%m%d_%H%M`
cd $file_dir

#pack log files
tar -zcvf $HOSTNAME.$date.tar.gz $logfiles

#upload to ftp server
ftp -n <<!
open $ftpaddr
user $ftpuser $ftppass
binary
#hash
cd deploy
cd zf
cd log
mkdir $Ftp_Server_Dir
cd $Ftp_Server_Dir
put $HOSTNAME.$date.tar.gz
close
bye
!
#delete packed file
rm -rf $HOSTNAME.$date.tar.gz

exit 0
