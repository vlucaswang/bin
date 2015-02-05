#!/bin/sh
echo Kdump Helper is starting to configure kdump service

#kexec-tools checking
if ! rpm -q kexec-tools > /dev/null
then 
    echo "kexec-tools not found, please run command yum install kexec-tools to install it"
    exit 1
fi
mem_total=`free -g |awk 'NR==2 {print $2 }'`
echo Your total memory is $mem_total G

#backup grub.conf
grub_conf=/boot/grub/grub.conf
grub_conf_kdumphelper=/boot/grub/grub.conf.kdumphelper.$(date +%y-%m-%d-%H:%M:%S)
echo backup $grub_conf to $grub_conf_kdumphelper
cp $grub_conf $grub_conf_kdumphelper
#     RHEL6 crashkernel compute
#     /*
#       https://access.redhat.com/site/solutions/59432
#
compute_rhel6_crash_kernel ()
{
    reserved_memory=128
    mem_size=$1
    kernel_subversion=`uname -r|awk -F"." '{print $3}'|awk -F"-" '{print $2}'`
    if [ $kernel_subversion -lt 220 ] ; then
        if [ $mem_size -le 2 ]
        then
            reserved_memory=128
        elif [ $mem_size -le 6 ]
        then
            reserved_memory=256
        elif [ $mem_size -le 8 ]
        then
            reserved_memory=512
        else
            reserved_memory=768
        fi
        echo "$reserved_memory"M
    fi

    if [ $kernel_subversion -ge 220 ] && [ $kernel_subversion -lt 279 ]; then # Check for kernel version > = 220 and RAM > = 4 GiB
    if [ $mem_size -ge 4 ];then
        reserved_memory="auto"
        echo "$reserved_memory"
    else # Check for kernel version > = 220 and RAM < 4 GiB
        reserved_memory=128
        echo "$reserved_memory"M
    fi
    fi

    if [ $kernel_subversion -ge 279 ] ; then   # Check for kernel version > = 279 and RAM > = 2 GiB
    if [ $mem_size -ge 2 ]
    then
        reserved_memory="auto"
        echo "$reserved_memory"
    else # Check for kernel version > = 279 and RAM < 2 GiB
    reserved_memory=128
    echo "$reserved_memory"M
    fi
    fi
}
crashkernel_para=`compute_rhel6_crash_kernel $mem_total `
echo crashkernel=$crashkernel_para is set in $grub_conf
grubby --update-kernel=DEFAULT --args=crashkernel=$crashkernel_para

#backup kdump.conf
kdump_conf=/etc/kdump.conf
kdump_conf_kdumphelper=/etc/kdump.conf.kdumphelper.$(date +%y-%m-%d-%H:%M:%S)
echo backup $kdump_conf to $kdump_conf_kdumphelper
cp $kdump_conf $kdump_conf_kdumphelper
dump_path=/var/crash
echo path $dump_path > $kdump_conf
dump_level=31
echo core_collector makedumpfile -c --message-level 1 -d $dump_level >> $kdump_conf
echo 'default reboot' >>  $kdump_conf

#enable kdump service
echo chkconfig kdump service on for 3 and 5 run levels
chkconfig kdump on --level 35
chkconfig --list|grep kdump

#kernel parameter change
echo Starting to Configure extra diagnostic opstions
sysctl_conf=/etc/sysctl.conf
sysctl_conf_kdumphelper=/etc/sysctl.conf.kdumphelper.$(date +%y-%m-%d-%H:%M:%S)
echo backup $sysctl_conf to $sysctl_conf_kdumphelper
cp $sysctl_conf $sysctl_conf_kdumphelper

#server hang
sed -i '/^kernel.sysrq/ s/kernel/#kernel/g ' $sysctl_conf 
echo >> $sysctl_conf
echo '#Panic on sysrq and nmi button, magic button alt+printscreen+c or nmi button could be pressed to collect a vmcore' >> $sysctl_conf
echo '#Added by kdumphelper, more information about it can be found in solution below' >> $sysctl_conf
echo '#https://access.redhat.com/site/solutions/2023' >> $sysctl_conf
echo 'kernel.sysrq=1' >> $sysctl_conf
echo 'kernel.sysrq=1 set in /etc/sysctl.conf'
echo '#https://access.redhat.com/site/solutions/125103' >> $sysctl_conf
echo 'kernel.unknown_nmi_panic=1' >> $sysctl_conf
echo 'kernel.unknown_nmi_panic=1  set in /etc/sysctl.conf'

