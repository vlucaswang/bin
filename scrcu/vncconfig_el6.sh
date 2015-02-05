#/bin/bash
userNum=2
#Preparetion: Stop the VNC server if it has been already started
service vncserver status
if [ $? -eq 0 ]; then
    service vncserver stop
fi
#Step1: Find the available port(s) for VNC service
port=5901
session=1
count=0
ports=()
sessions=()
currentTimestamp=`date +%y-%m-%d-%H:%M:%S`
while [ "$count" -lt "$userNum" ]; do
    netstat -a | grep ":$port\s" >> /dev/null
    if [ $? -ne 0 ]; then
        ports[$count]=$port
        sessions[$count]=$session
        count=`expr $count + 1`
        echo $port" is available for VNC service"
    fi
    session=`expr $session + 1`
    port=`expr $port + 1`
done

#Step2: Write the VNC configuration into the /etc/sysconfig/vncservers
#Backup configuration files
vnc_conf=/etc/sysconfig/vncservers
vnc_conf_backup=/etc/sysconfig/vncservers.vncconfig.$currentTimestamp
if [ -f "$vnc_conf" ]; then
    echo backup $vnc_conf to $vnc_conf_backup
    cp $vnc_conf $vnc_conf_backup
fi

echo '
VNCSERVERS="'${sessions[0]}':root '${sessions[1]}':oracle"

VNCSERVERARGS['${sessions[0]}']="-geometry 1024x768 -nolisten tcp"

VNCSERVERARGS['${sessions[1]}']="-geometry 1024x768 -nolisten tcp"

'>/etc/sysconfig/vncservers

#Step3 Set up the VNC password for each user

echo "Please set the VNC password for user root"

vncpasswd


echo "Please set the VNC password for user oracle"

su - oracle -c vncpasswd



#Step 4: Set the desktop enviroment

xstartupContent='#!/bin/sh
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
vncconfig -iconic &
dbus-launch --exit-with-session gnome-session &
'

#Backup files
vnc_conf=~root/.vnc/xstartup
vnc_conf_backup=~root/.vnc/xstartup.vncconfig.$currentTimestamp
if [ -f "$vnc_conf" ]; then
    echo backup $vnc_conf to $vnc_conf_backup
    cp $vnc_conf $vnc_conf_backup
fi

echo "$xstartupContent" > ~root/.vnc/xstartup
chmod 755 ~root/.vnc/xstartup

#Backup files
vnc_conf=~oracle/.vnc/xstartup
vnc_conf_backup=~oracle/.vnc/xstartup.vncconfig.$currentTimestamp
if [ -f "$vnc_conf" ]; then
    echo backup $vnc_conf to $vnc_conf_backup
    cp $vnc_conf $vnc_conf_backup
fi

echo "$xstartupContent" > ~oracle/.vnc/xstartup
chmod 755 ~oracle/.vnc/xstartup


#Step5:Start the VNC service
#Start the VNC service
service vncserver start
#Set the VNC service start by default
chkconfig vncserver on
#Verify the VNC Service
chkconfig --list vncserver

#Step6: If default firewall is used, we will open the VNC ports


#Step7: Echo the information that VNC client can connect to

myIP=$(hostname  -I | cut -f1 -d' ')

echo "The available link(s) for VNC Client:"

echo "vncviewer "$myIP:"${sessions[0]}"

echo "vncviewer "$myIP:"${sessions[1]}"
