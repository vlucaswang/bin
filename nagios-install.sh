#!/bin/sh
ifconfig
cd /etc/yum.repos.d/
yum install wget -y
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo
yum makecache
cd /opt
getenforce
setenforce 0
yum install vim -y
vim /etc/selinux/config
service iptables stop
chkconfig iptables off
yum update -y
yum install -y httpd php gcc glibc glibc-common gd gd-devel php-gd make net-snmp
reboot
cd /tmp/
wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-3.5.0.tar.gz
wget http://prdownloads.sourceforge.net/sourceforge/nagiosplug/nagios-plugins-1.4.16.tar.gz
tar zxvf nagios-3.5.0.tar.gz
tar zxvf nagios-plugins-1.4.16.tar.gz
useradd -s /sbin/nologin nagios
groupadd nagcmd
usermod -a -G nagcmd nagios
cd nagios
./configure --with-command-group=nagcmd
make all
make install;make install-init;make install-config;make install-commandmode;make install-webconf
cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/
chown -R nagios:nagios /usr/local/nagios/libexec/eventhandlers
/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
/etc/init.d/nagios start
service httpd start
vim /etc/hosts
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
chkconfig nagios on
cd ../nagios-plugins-1.4.16
yum install openssl-devel -y
./configure --with-nagios-user=nagios --with-nagios-group=nagios && make && make install

vim /etc/group
nagios:x:500:nagios,apache
nagcmd:x:501:nagios,apache 

yum install perl-Time-HiRes perl-rrdtool -y
