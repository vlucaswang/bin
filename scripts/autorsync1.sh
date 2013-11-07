#!/bin/bash

SRC1=/var/samba/nightly/
DST1=root@192.168.31.7::nightly

#SRC2=/var/samba/public/
#DST2=root@192.168.31.7::public

/usr/local/inotify/bin/inotifywait -mrq -e close_write,delete,create,attrib $SRC1 | while read D E F
do
#/usr/bin/rsync -rltDzv --delete --password-file=/etc/rsyncd.secrets $SRC1 $DST1 >> /root/rsyncd.log
/usr/bin/rsync -rltDzv --delete /var/samba/nightly/ 192.168.31.7:/volume1/nightly >> /root/rsyncd.log
done

#/usr/local/inotify/bin/inotifywait -mrq -e close_write,delete,create,attrib $SRC2 | while read D E F
#do
#/usr/bin/rsync -rltDzv --delete --exclude "ISO" --password-file=/etc/rsyncd.secrets $SRC2 $DST2 >> /root/rsyncd.log
#/usr/bin/rsync -rltDzv --delete --exclude "ISO" /var/samba/public/ 192.168.31.7:/volume1/public >> /root/rsyncd.log
#done
