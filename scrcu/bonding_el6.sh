#!/bin/bash
ethtool eth0 |grep "Link detected: yes"> /dev/null
if [ $? -ne 0 ] ;then
    echo Can not detect the link of eth0
    exit 1
fi

ethtool eth4 |grep "Link detected: yes"> /dev/null
if [ $? -ne 0 ] ;then
    echo Can not detect the link of eth4
    exit 1
fi

set_rhel6_bond_config ()
{
unset OPTIND
while getopts 'b:m:i:n:g:s:t:' opt; do
    case $opt in
        b) bond_name=$OPTARG;;
        m) bond_mode=$OPTARG;;
        i) ip=$OPTARG;;
        n) mask=$OPTARG;;
        g) gateway=$OPTARG;;
        s) bond_opts=$OPTARG;;
        t) network_type=$OPTARG;;
    esac
done
bond_config_file="/etc/sysconfig/network-scripts/ifcfg-$bond_name"
echo $bond_config_file
if [ -f $bond_config_file ]; then
    echo "Backup original $bond_config_file to bondhelper.$bond_name"
    mv $bond_config_file /etc/sysconfig/network-scripts/bondhelper.$bond_name -f
fi

if [ "static" == $network_type ]; then 
    ip_setting="IPADDR=$ip
NETMASK=$mask
GATEWAY=$gateway
USERCTL=no"
else
    ip_setting="USERCTL=no"
fi
cat << EOF > $bond_config_file
DEVICE=$bond_name
ONBOOT=yes
BOOTPROTO=$network_type
$ip_setting
BONDING_OPTS="mode=$bond_mode $bond_opts"
NM_CONTROLLED=no
EOF
}
set_rhel6_bond_config -b bond0 -m 4 -i 10.4.4.22 -n 255.255.252.0 -g 10.4.4.1 -t static -s "miimon=100 xmit_hash_policy=layer2+3"

set_rhel6_ethx_config()  {
    bond_name=$1
    eth_name=$2

    eth_config_file="/etc/sysconfig/network-scripts/ifcfg-$eth_name"
    if [ -f $eth_config_file ]; then
        echo "Backup original $eth_config_file to bondhelper.$eth_name"
        mv $eth_config_file /etc/sysconfig/network-scripts/bondhelper.$eth_name -f
    fi

    cat << EOF  > $eth_config_file
DEVICE=$eth_name
BOOTPROTO=none
ONBOOT=yes
MASTER=$bond_name
SLAVE=yes
USERCTL=no
NM_CONTROLLED=no
EOF
}

set_rhel6_ethx_config bond0 eth0
set_rhel6_ethx_config bond0 eth4

echo "Network service will be restarted."
service network restart
cat /proc/net/bonding/bond0
