#!/bin/sh
LOCALWORKDIR=/var/samba/nightly
SERVERURL=http://newbuild.talend.com/builds
SERVERUSER=build-admin
SERVERPASSWORD=remy_build

if [ ! -f $LOCALWORKDIR/lock ]; then
 touch $LOCALWORKDIR/lock

 #change directory
 cd $LOCALWORKDIR

 #download build txt list
 rm -rf $LOCALWORKDIR/lastnb.txt
 wget -N --user=$SERVERUSER --password=$SERVERPASSWORD $SERVERURL/lastnb.txt
 LASTNB=$(head -n 1 $LOCALWORKDIR/lastnb.txt | cut -d "/" -f 5)
 echo $LASTNB
 mkdir $LASTNB
 cd $LASTNB
 #download builds
 wget -N --user=$SERVERUSER --password=$SERVERPASSWORD -i $LOCALWORKDIR/lastnb.txt
  
  rm $LOCALWORKDIR/lock
fi
