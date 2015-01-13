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
        10.4.4.32)
            change 32
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        10.4.4.33)
            change 33
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        10.4.4.70)
            change 70
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
        echo "Please input machine ip(10.4.4.32 10.4.4.33 10.4.4.70)"
            echo $"Usage: $0 [10.4.4.32 10.4.4.33 10.4.4.70]"
            RETVAL=2
esac
echo "Current bond0 IP is $(ip -4 -o addr show dev bond0|awk '{split($4,a,"/");print a[1]}')!"
exit $RETVAL