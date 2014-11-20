#!/bin/bash

current_ip=`grep IPADDR /etc/sysconfig/network-scripts/ifcfg-eth0 | awk -F = '{print $2}'`
#new_ip="10.4.4.$1"

change()
{
#    /bin/sed -i "s/$current_ip/$new_ip/g" /etc/sysconfig/network-scripts/ifcfg-eth0;
    /bin/sed -i "s/$current_ip/10.4.4.$1/g" /etc/sysconfig/network-scripts/ifcfg-eth0;
}
echo "Current ifcfg-eth0 IP is $current_ip!"
case "$1" in
        a)
            change 22
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        b)
            change 23
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        c)
            change 34
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        backup)
            change 68
            sleep 2
            /sbin/service network restart
            ping -c 1 10.4.4.1
            RETVAL=0
            ;;
        *)
            echo "请输入机器节点编号(a,b或c)."
            echo $"Usage: $0 [a b c]"
            RETVAL=2
esac
echo "Current eth0 IP is $(ip -4 -o addr show dev eth0|awk '{split($4,a,"/");print a[1]}')!"
exit $RETVAL