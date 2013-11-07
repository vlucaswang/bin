#!/bin/bash
rm /var/samba/nightly/lastswtbot*
cd /var/samba/nightly/
#&& find /var/samba/nightly/ -name "*.zip" -mtime +4 -exec rm {} \;
wget --user=build-admin --password=remy_build http://build.talend.com/builds/lastnb.txt
#wget --input-file=lastnb.txt

cat lastnb.txt |xargs wget --user=build-admin --password=remy_build -
rm lastnb.txt
