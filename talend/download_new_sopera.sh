#!/bin/sh
LOCALWORKDIR=/var/samba/nightly
SERVERURL=http://ftp.sopera.com/builds
#SERVERUSER=build-admin
#SERVERPASSWORD=remy_build

if [ ! -f $LOCALWORKDIR/lock ]; then
 touch $LOCALWORKDIR/lock

 #change directory
 cd $LOCALWORKDIR

 #download build txt list
 #rm -rf $LOCALWORKDIR/lastnb.txt
 #wget -N $SERVERURL/lastnb.txt
 #replace the original url to ftp.sopera.com
 sed -i s/newbuild.talend.com/ftp.sopera.com/g $LOCALWORKDIR/lastnb.txt

 LASTNB=$(head -n 1 $LOCALWORKDIR/lastnb.txt | cut -d "/" -f 5)
 echo $LASTNB
 mkdir $LASTNB
 cd $LASTNB
 #download builds
 wget -N -i $LOCALWORKDIR/lastnb.txt
  
  rm -f $LOCALWORKDIR/lock
fi
