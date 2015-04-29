#!/bin/bash

#########################################
#Function:    update openssl & openssh on linux os
#Usage:       bash openssh_upgrade.sh
#Author:      Xiaochuan Wang
#Company:     SYSSSC
#Version:     1.1
#########################################

####################Start###################
# check lock file ,one time only let the script run one time
LOG_PATH=/tmp/sysssc
LOG_FILE=$(date)
LOCKfile=$LOG_PATH/.$(basename $0).lock
OPENSSLDIR=/usr/local/openssl-1.0.2a
OPENSSHDIR=/opt/ssh

export LANG=en_US
export LC_CTYPE=en_US
export PATH=/usr/bin:$PATH

if [ -f "$LOCKfile" ]
then
  echo -e "\033[1;40;31mThe script is already exist,please next time to run this script.\n\033[0m"
  exit 2
else
  echo -e "\033[40;32mStep 0.No lock file,begin to create lock file and continue.\n\033[40;37m"
  touch $LOCKfile
fi

# check user
if [ $(id -u) != "0" ]
then
  echo -e "\033[1;40;31mError: You must be root to run this script, please use root to install this script.\n\033[0m"
  rm -rf $LOCKfile
  exit 3
fi

rm -rf ${LOG_PATH}

# Create directory for outputs.
if [ ! -d ${LOG_PATH} ]
then
	mkdir -p ${LOG_PATH}
fi

#yum install gcc make pam-devel -y
rpm -qa | grep gcc && rpm -qa | grep make && rpm -qa | grep pam-devel && rpm -qa | grep zlib-devel
if [ $? -eq 1 ]
then
	echo 'Package gcc or make or pam-devel or zlib-devel is not installed.'
	rm -rf $LOCKfile
	exit 4
fi

exec 2>>"${LOG_PATH}/${LOG_FILE}_err"
#exec >>"${LOG_PATH}/${LOG_FILE}_log"

cd `dirname $0`
echo `pwd`

echo "Update begin:"
echo `date`

# start telnet incase ssh break
sed -ri 's,^([ \t]*disable[ \t]*=[ \t]*)yes,\1no,' /etc/xinetd.d/telnet
service xinetd restart

rm -rf $OPENSSLDIR && rm -f /usr/local/openssl && rm -rf $OPENSSHDIR

# compiling openssl
tar zxvf openssl-1.0.2a.tar.gz
cd openssl-1.0.2a
./config --shared --prefix=$OPENSSLDIR
make && make test && make install
grep $OPENSSLDIR/lib /etc/ld.so.conf.d/openssl.conf >/dev/null 2>&1
if [ $? -ne 0 ]
then
	echo $OPENSSLDIR/lib > /etc/ld.so.conf.d/openssl.conf
fi
ldconfig -v
ln -s $OPENSSLDIR /usr/local/openssl
grep '/usr/local/openssl' /etc/profile >/dev/null 2>&1
if [ $? -ne 0 ]
then
	cp /etc/profile{,.bak}
	cat >> /etc/profile <<EOF
	PATH=/usr/local/openssl/bin:\$PATH
	export PATH
EOF
fi

mv /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
mv /etc/ssh/ssh_config /etc/ssh/ssh_config.bak

# compiling openssh
cd ..
tar zxvf openssh-6.8p1.tar.gz
cd openssh-6.8p1
./configure --prefix=$OPENSSHDIR --sysconfdir=/etc/ssh --with-pam --with-ssl-dir=$OPENSSLDIR --with-md5-passwords --with-zlib
make && make install
cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
cp /etc/ssh/ssh_config.bak /etc/ssh/ssh_config
grep "$OPENSSHDIR" /etc/profile >/dev/null 2>&1
if [ $? -ne 0 ]
then
	cat >> /etc/profile <<EOF
	PATH=$OPENSSHDIR/bin:\$PATH
	export PATH
EOF
fi
#cp /etc/init.d/sshd{,.bak}
#sed -i -e "s@^KEYGEN=.*@KEYGEN=$OPENSSHDIR\/bin\/ssh-keygen@" /etc/init.d/sshd
sed -i -e 's/\(^GSSAPI.*$\)/#\1/' -e 's/#UseDNS yes/UseDns no/g' -e '/^#Protocol 2/s/#Protocol 2/Protocol 2/' /etc/ssh/sshd_config
cp /usr/bin/ssh-keygen{,.bak}
cp $OPENSSHDIR/bin/ssh-keygen /usr/bin/ssh-keygen -f
cp /usr/sbin/sshd{,.bak}
service sshd stop
cp $OPENSSHDIR/sbin/sshd /usr/sbin/sshd -f
service sshd start

# check openssl & openssh version
ssh -V
sshd -V

rm -rf $LOCKfile
echo `date`
echo "Update ended."

exit 0