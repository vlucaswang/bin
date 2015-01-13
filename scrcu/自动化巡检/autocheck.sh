#!/bin/bash

# Provided by Xiaochuan Wang
# xiaochuan.wang@sysssc.com
# 
# 12/12 Add count errors

LOG_PATH=/tmp/sysssc
LOG_FILE=`hostname`_`echo $(/sbin/ifconfig | awk '/inet addr/{print substr($2,6)}' | grep -v 127.0) | sed "s/ /_/g"`
MON_DB_LOG=/tmp/mon_db/mon_db.log
COMMENT_FILE=/etc/comment.txt

ALERT=90
HVALUE=0
MVALUE=0
OVALUE=0
SVALUE=0
DVALUE=0

# Run as root.
if  [ "$EUID" -ne 0 ];then
	echo "Must be root to run this script."
	exit 87
fi

rm -rf ${LOG_PATH}

# Create directory for outputs.
if [ ! -d ${LOG_PATH} ]
then
	mkdir -p ${LOG_PATH}/Logs
fi

# set -e
# set -x
# Setup logging
# Logs stderr and stdout to separate files.
#exec 2>>"${LOG_PATH}/${LOG_FILE}_err"
exec 2>>"${LOG_PATH}/Logs/${LOG_FILE}_log"
exec >>"${LOG_PATH}/Logs/${LOG_FILE}_log"

function check_fs() {
while read line; do
  util=$(echo $line | awk '{ print $1}' | cut -d'%' -f1)
  fs=$(echo $line | awk '{print $2}')
  if [ ! "$util" == "" ]; then
  	if [ $util -ge $ALERT ]; then
    	echo "Running out of space \"$fs ($util%)\"."
	OVALUE=`echo "$OVALUE+1"|bc`
	else
	echo "File system normal \"$fs ($util%)\"."
  	fi
  fi
done
}

function big_separater() {
	echo "- - - - - - - - -  $1   - - - - - - - - -"
}

function separater() {
	echo "========== $1 ==========";
}

function daily_check0() {
	if [ $? -ne 0 ]; then
	OVALUE=`echo "$OVALUE+1"|bc`
	echo "$1"
	echo $commline | bash >> ${LOG_PATH}/${LOG_FILE}_.txt
	fi
}

function daily_check1() {
	if [ $? -ne 1 ];then
	OVALUE=`echo "$OVALUE+1"|bc`
	echo $commline | bash >> ${LOG_PATH}/${LOG_FILE}_.txt
	else
	if [ -n "$1" ];then
	echo "$1"
	fi
	fi
}
cd ${LOG_PATH}

# OS Info
big_separater "OS Info"
separater "hostname"
hostname
separater "network interfaces & IP"
ip -f inet -o addr show|cut -d" " -f2,7 | grep -v 127.
separater "OS dist"
cat /etc/*release
separater "OS arch"
uname -m
separater "OS load"
uptime
separater "OS date"
date +%Y%m%d%k%M%S

# Hardware Info
big_separater "Hardware Info"
lscpu
free -m

# Software Info
big_separater "Software Info"
#getent passwd | egrep -v "nologin|shutdown|halt|news|sync|false"
#getent passwd | egrep -v "nologin|shutdown|halt|news|sync|false" | awk -F: '{print $1}' | while read name; do groups $name; done
iptables -L
getenforce
env | egrep "^LANG|^PATH"
egrep -v "^#|^$" /etc/rc.d/boot.local /etc/rc.local
getent passwd | cut -d: -f1 | perl -e'while(<>){chomp;$l = `crontab -u $_ -l 2>/dev/null`;print "$_\n$l\n" if $l}'
egrep -v "^#|^$" /etc/fstab
egrep -v "^#|^$" /proc/net/bonding/bond0
ntpq -p

last | grep "`date -d "1 day ago" "+%b %_d"`"
last reboot
lastlog -t 1
lastb

# Software Filesystem
big_separater "Software Filesystem"
fdisk -l
pvs
vgs
lvs
df -hP

# Software DB2
#db2ls
big_separater "Software DB2"
getent passwd|grep db2inst1
if [ $? -eq 0 ];then
su - db2inst1 -c 'db2licm -l'
else
echo "DB2 is not installed"
fi

exec >>${LOG_PATH}/${LOG_FILE}_.txt
# Daily check
echo `date +%Y%m%d%k%M%S`> ${LOG_PATH}/${LOG_FILE}_.txt

#[daily_check0] return 0 is true
big_separater "Daily_check"

#separater "Ping GW"
#ping -c 1 -w 1 `ip route | awk '/default/ { print $3 }'` >/dev/null 2>&1
#if [ $? -eq 0 ];then
#echo "Ping GW success"
#else
#echo "Ping GW Fail"
#OVALUE=`echo "$OVALUE+1"|bc`
#fi

#[check_fs]
separater "Check File System"
df -hP | grep -vE "^[^/]|tmpfs|cdrom|sr" | awk '{print $5 " " $6}' | check_fs
df -iP | grep -vE "^[^/]|tmpfs|cdrom|sr" | awk '{print $5 " " $6}' | check_fs

separater "NTP"
commline="egrep -v '^#|^$' /etc/ntp.conf | grep '10.128.128'";echo $commline | bash;daily_check0;unset commline

separater "Ping Ntp Server"
for IP in `egrep -v "^#|^$" /etc/ntp.conf | grep "server 10" | cut -d" " -f2`
do
        ping -c 1 -w 1 ${IP} >/dev/null 2>&1
if [ $? -eq 0 ];then 
echo "Ping Ntp Server success"
else
echo "Ping Ntp Server Fail"
OVALUE=`echo "$OVALUE+1"|bc`
fi
done

#separater "Find Abnormal file"
#commline="find / -nogroup -nouser 2>/dev/null";$commline;daily_check0;unset commline

separater "PatrolAgent"
commline="ps -ef | grep PatrolAgent |grep -v grep";echo $commline | bash ; true ;daily_check0 "There is no PatrolAgent";unset commline

separater "root privilege"
commline="getent passwd 0 | grep -v ^root:";echo $commline | bash;daily_check1 "no user have root privilege";unset commline

#separater "Find Abnormal Progress"
#commline="ps aux | egrep 'D|Z' | grep -v egrep | grep -v USER";echo $commline | bash;daily_check1;unset commline

#egrep -4 'failed | restart.' /var/log/boot.log /var/log/messages /var/log/dmesg | grep -v 'OK' | grep "`date -d "1 day ago" "+%b %_d"`" 

#grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print int(usage)}'

separater "Check Timezone"
TISET=`grep -v ^# /etc/sysconfig/clock | awk -F\" '/ZONE/ {print $2}'`
case $TISET in
        Asia/Shanghai)
        echo "Timezone is Asia/Shanghai"
        ;;
        Asia/Chongqing)
       	echo "Timezone is Asia/Chongqing"
        ;;
        *)
        echo "The wrong TIMEZONE=$TISET"
	OVALUE=`echo "$OVALUE+1"|bc`
        ;;
esac

separater "Check nofile"
#FISET=`cat /etc/security/limits.conf | grep nofile |grep -v ^# |awk '/soft/ {print $4}'`
#if [ -n "$FISET" ];then
#if [ "$FISET" -lt "1024" ];then
#        echo "nofile set wrong"
#	OVALUE=`echo "$OVALUE+1"|bc`
#fi
#else
#echo "nofile is not set"
#OVALUE=`echo "$OVALUE+1"|bc`
#fi

#awk '{print $3 " " $4 " " $11 " " $12}' /proc/net/dev | grep [0-9]
# egrep -4 'failed | Invalid | disabled | not | warning | possible | handled | restart.' /var/log/boot.log /var/log/messages /var/log/dmesg
# egrep -4 'failed | Invalid | disabled | warning | restart.' /var/log/boot.log /var/log/messages /var/log/dmesg | grep -v "OK"

if [ -f $MON_DB_LOG ]; then
HVALUE=`awk 'END{print $NF}' $MON_DB_LOG`
fi

if [ -f $COMMENT_FILE ]; then
EXTRAVALUE1="`awk -F '=' 'NR==6 {print $2}' $COMMENT_FILE`(`awk -F '=' 'NR==7 {print $2}' $COMMENT_FILE`)"
EXTRAVALUE2="`awk -F '=' 'NR==8 {print $2}' $COMMENT_FILE`"
fi

big_separater "The Number of errors in daily check"
echo "$EXTRAVALUE1,$EXTRAVALUE2,$HVALUE,$SVALUE,$OVALUE,$MVALUE,$DVALUE"
#big_separater ""

cat "${LOG_PATH}/${LOG_FILE}_.txt" >> "${LOG_PATH}/Logs/${LOG_FILE}_log" 

#free | awk '/buffers\/cache/{print int($3/($3+$4) * 100.0);}' | check_fs

# ftp upload

exec 2>> /dev/null
exec >>/dev/null

#FTPHOST=10.128.128.103
#FTPUSER=test
#FTPPASS=test
#Directory=`date +%Y%m%d`
#
#ftp -v -n $FTPHOST <<EOF
#user $FTPUSER $FTPPASS
#binary
#prompt
#mkdir $Directory
#cd $Directory
#mkdir Logs
#cd Logs
#mput "${LOG_FILE}_log" "${LOG_FILE}_err"
#cd ..
#mput "${LOG_FILE}_.txt"
#bye
#EOF

exit 0
