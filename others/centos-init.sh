#!/bin/sh

#Disable SELinux
sed -i 's/SELINUX\=enforcing/SELINUX\=disabled/g' /etc/selinux/config

#Shutdown iptables and disable from boot
/etc/init.d/iptables stop
/etc/init.d/ip6tables stop
/sbin/chkconfig iptables off
/sbin/chkconfig ip6tables off
