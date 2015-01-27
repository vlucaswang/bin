#!/bin/bash

DD=`date +%Y%m%d`
NTPPATH=/home/test
REPORTPATH=/home/test1

mkdir -p $REPORTPATH/$DD
mkdir -p $NTPPATH/$DD

for i in `cat /root/ansible/hosts_20150114 |grep -v "\["|grep -v '^#' |awk '{print $1}'`
do
rsync -avzq $i:/tmp/sysssc/ $REPORTPATH/$DD
rsync -avzq $i:/tmp/ntp/ $NTPPATH/$DD
done

if [ -d $NTPPATH/$DD ]; then
  cd $NTPPATH/$DD
  rm -f all.txt
  cat * > all.txt
fi
