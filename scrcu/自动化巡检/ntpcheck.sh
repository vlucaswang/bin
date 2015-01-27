#!/bin/bash

ERR_NO=0
SERVICE_PATH=/etc/init.d
SERVICE_RHEL=ntpd
SERVICE_SUSE=ntp
LOGPATH=/tmp/ntp
LOGFILE=$LOGPATH/`hostname`_`echo $(/sbin/ifconfig | grep -Ev "127.0|192.168" | awk '/inet addr/{print substr($2,6)}' | awk '{{printf"%s_",$0}}' )`.txt
COMMENT_FILE=/etc/comment.txt

#set -x

function checkstatus0() {
  if [ $? -eq "0" ]; then
    echo -n ',0' >> $LOGFILE
  else
    echo -n ',1' >> $LOGFILE
    ERR_NO=`echo "$ERR_NO+1"|bc`
  fi
}

function checkstatus1() {
  if [ $? -ne "0" ]; then
    echo -n ',0' >> $LOGFILE
  else
    echo -n ',1' >> $LOGFILE
    ERR_NO=`echo "$ERR_NO+1"|bc`
  fi
}

mkdir -p $LOGPATH || ( rm -rf $LOGPATH && mkdir -p $LOGPATH )

#IP address
echo -n $(/sbin/ifconfig | awk '/inet addr/{print substr($2,6)}' | grep -Ev "127.0|192.168") > $LOGFILE

#Application Name
if [ -f $COMMENT_FILE ]; then
EXTRAVALUE1="`awk -F '=' 'NR==6 {print $2}' $COMMENT_FILE`(`awk -F '=' 'NR==7 {print $2}' $COMMENT_FILE`)"
#EXTRAVALUE2="`awk -F '=' 'NR==8 {print $2}' $COMMENT_FILE`"
fi
echo -n ",$EXTRAVALUE1" >> $LOGFILE
#echo -n ",$EXTRAVALUE2" >> $LOGFILE

#current ntp upstream server
echo -n ",$(ntpq -p | awk '/[0-9]/{print $1}' | tr '\n' ' ' | sed 's/ $//')" >> $LOGFILE

#time diff with ntp server
echo -n ",$(ntpdate -q 10.128.128.115 | awk 'NR==2&&/offset/ {print $10}')" >> $LOGFILE

#ntp service is running or not
ps -ef | grep -Ev "grep|check" | grep $SERVICE_SUSE
checkstatus0

#ntp service is start on boot or not
chkconfig --list | grep "^$SERVICE_SUSE.*3:on"
checkstatus0

#ntp.conf is proper configuared or not
grep "server *10.128.128" /etc/ntp.conf
checkstatus0

#ntpdate in crontab or not
crontab -l | grep ntpdate
checkstatus1

#vmware-toolbox-cmd timesync is enabled or not
vmware-toolbox-cmd timesync status
checkstatus1

#local machine timezone
grep -E "Shanghai|Chongqing" /etc/sysconfig/clock
checkstatus0

#input total count of error number
echo ",$ERR_NO" >> $LOGFILE

exit 0
