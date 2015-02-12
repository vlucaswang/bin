#!/bin/bash

#########################################
#Function:    extend lv on linux os
#Usage:       bash scrcu_extend_lvm.sh
#Author:      Xiaochuan Wang
#Company:     SYSSSC
#Version:     1.0
#########################################



####################Start###################
#check lock file ,one time only let the script run one time
LOCKfile=/tmp/.$(basename $0)
MOUNTPATH=/data
VGNAME=rootvg
LVNAME=datalv
SIZE=90

if [ -f "$LOCKfile" ]
then
  echo -e "\033[1;40;31mThe script is already exist,please next time to run this script.\n\033[0m"
  exit 2
else
  echo -e "\033[40;32mStep 0.No lock file,begin to create lock file and continue.\n\033[40;37m"
  touch $LOCKfile
fi

#check user
if [ $(id -u) != "0" ]
then
  echo -e "\033[1;40;31mError: You must be root to run this script, please use root to install this script.\n\033[0m"
  rm -rf $LOCKfile
  exit 1
fi

# Scan new devices
for HOST in `ls /sys/class/scsi_host/`
do
  echo "- - -" > /sys/class/scsi_host/$HOST/scan
done

# Scan new partitions
for x in `ls /sys/class/scsi_device/`
do
  echo 1 > /sys/class/scsi_device/$x/device/rescan
done

# Find new block device
pvs | awk '/\//{print substr($1,0,8)}' > /tmp/1
ls -l /dev/sd? | awk '{print substr($10,0,8)}' > /tmp/2
NEWDISK=$(comm -13 /tmp/1 /tmp/2)

echo -e "n\np\n1\n\n\nt\n8e\nw" | fdisk $NEWDISK

partx -a $NEWDISK

NEWPART=$(ls $NEWDISK?)

echo -e "\nAdding device $NEWPART to LVM ..."
pvcreate $NEWPART
echo -e "\nExtending LVM Volume Group $VGNAME ..."
vgextend $VGNAME $NEWPART
echo -e "\nExtending LVM Logical Volume to all available free space in Volume Group ..."
lvextend -l +${SIZE}%FREE /dev/$VGNAME/$LVNAME
echo -e "\nResizing file system on $LVNAME ..."
resize2fs /dev/$VGNAME/$LVNAME

rm -rf $LOCKfile
echo -e "\n$MOUNTPATH extension complete!"
exit 0