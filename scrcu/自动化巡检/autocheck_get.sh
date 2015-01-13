#!/bin/bash

DD=`date +%Y%m%d`
mkdir -p /home/test1/$DD

for i in `cat /root/ansible/tmphost6 |grep -v ^# |awk '{print $1}'`
do
rsync -avzq $i:/tmp/sysssc/ /home/test1/$DD
done
