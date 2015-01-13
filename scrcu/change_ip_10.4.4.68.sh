#!/bin/bash

NETPATH='/etc/sysconfig/network-scripts'
current_ip=`grep IPADDR= $NETPATH/ifcfg-bond0 | awk -F = '{print $2}'`
#new_ip="10.4.4.$1"

change()
{
#    /bin/sed -i "s/$current_ip/$new_ip/g" $NETPATH/ifcfg-bond0;
    /bin/sed -i "s/$current_ip/10.4.4.$1/g" $NETPATH/ifcfg-bond0;
}
echo "Current ifcfg-bond0 IP is $current_ip!"
case "$1" in
        10.4.4.22)
            change 22
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        10.4.4.23)
            change 23
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        10.4.4.34)
            change 34
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        10.4.4.68)
            change 68
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        10.4.4.211)
            change 211
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        *)
        echo "Please input machine ip(10.4.4.22, 10.4.4.23, 10.4.4.34, 10.4.4.68)"
            echo $"Usage: $0 [10.4.4.22 10.4.4.23 10.4.4.34 10.4.4.68]"
            RETVAL=2
esac
echo "Current bond0 IP is $(ip -4 -o addr show dev bond0|awk '{split($4,a,"/");print a[1]}')!"
exit $RETVAL