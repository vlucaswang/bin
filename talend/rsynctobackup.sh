#!/bin/sh

rsync -rltDzv --delete /var/samba/nightly/ 192.168.31.7:/volume1/nightly
rsync -rltDzv --delete --exclude "ISO" /var/samba/public/ 192.168.31.7:/volume1/public
