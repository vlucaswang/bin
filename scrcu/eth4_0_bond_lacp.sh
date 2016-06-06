#!/bin/bash

#Setup bonding mode 4 for LACP

NETPATH='/etc/sysconfig/network-scripts'
REALIP1=$(grep IPADDR= $NETPATH/ifcfg-eth4 | awk -F = '{print $2}')
REALIP2=$(grep IPADDR2 $NETPATH/ifcfg-eth4 | awk -F = '{print $2}')

service NetworkManager stop
chkconfig NetworkManager off

testf -f ifcfg-eth0.$(date +%Y%m%d).bak || mv $NETPATH/ifcfg-eth0 $NETPATH/ifcfg-eth0.$(date +%Y%m%d).bak
testf -f ifcfg-eth4.$(date +%Y%m%d).bak || mv $NETPATH/ifcfg-eth4 $NETPATH/ifcfg-eth4.$(date +%Y%m%d).bak

cat > $NETPATH/ifcfg-eth0 <<EOF
DEVICE=eth0
ONBOOT=yes
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
EOF

cat > $NETPATH/ifcfg-eth4 <<EOF
DEVICE=eth4
ONBOOT=yes
BOOTPROTO=none
MASTER=bond0
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
EOF

cat > $NETPATH/ifcfg-bond0 <<EOF
DEVICE=bond0
BOOTPROTO=none
ONBOOT=yes
NM_CONTROLLED=no
USERCTL=no
IPADDR=$REALIP1
NETMASK=255.255.252.0
GATEWAY=10.4.4.1
IPADDR2=$REALIP2
NETMASK2=255.255.255.0
GATEWAY2=192.168.6.1
BONDING_OPTS="mode=4 miimon=100"
EOF

cat >> /etc/modprobe.d/bonding.conf <<EOF
alias bond0 bonding
#options bonding mode=4 miimon=100 
EOF

modprobe bonding

sleep 2
/etc/init.d/network restart
chkconfig network on

ifup eth0
ifup eth4
ifup bond0

cat /proc/net/bonding/bond0

exit 0
