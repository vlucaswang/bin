#!/bin/bash

# Configure & Start VNC Server
# Version 3

DATE=$(date +%Y%m%d)
ROOT_UID=0
VNCCONF=/etc/sysconfig/vncservers
USERHOME=$(grep "^$1:" /etc/passwd | awk -F: '{print $6}')
USERGROUP=$(grep "^$1:" /etc/passwd | awk -F: '{print $4}')

if [ "$EUID" -ne "$ROOT_UID" ];then
  echo "Must be root to run this script."
  exit 87
fi

if [ $# -ne 2 ];then
  echo "Usage: $0 {username} {vnc_password}" >&2
  exit 1
fi

yum install tightvnc-server -y

echo "VNCSERVERS=\"1:root 2:$1\"" >> $VNCCONF
echo 'VNCSERVERARGS[1]="-geometry 1024x768 -alwaysshared"' >> $VNCCONF
echo 'VNCSERVERARGS[2]="-geometry 1024x768 -alwaysshared"' >> $VNCCONF
mkdir -p /root/.vnc
mkdir -p ${USERHOME}/.vnc
echo "$2" | vncpasswd -f > /root/.vnc/passwd
echo "$2" | vncpasswd -f > ${USERHOME}/.vnc/passwd
chmod 600 /root/.vnc/passwd ${USERHOME}/.vnc/passwd
chown $1.$USERGROUP ${USERHOME}/.vnc/passwd

service vncserver start
service vncserver stop

sed -i.$DATE.bak 's/twm & /gnome-session &/g' /root/.vnc/xstartup
#chmod 755 /root/.vnc/xstartup

sed -i.$DATE.bak 's/twm & /gnome-session &/g' ${USERHOME}/.vnc/xstartup
#chmod 755 /home/oracle/.vnc/xstartup

service vncserver start
chkconfig vncserver on