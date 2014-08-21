#!/bin/bash

#Init SCRCU vsftpd conf files
#Provided by Xiaochuan Wang
#xiaochuan.wang@sysssc.com

FTPBANNER="Welcome to SCRCU FTP!"
USERFILE=/etc/vsftpd/virtusers
USERDB=/etc/vsftpd/virtusers.db
CONFBASE=/etc/vsftpd/vconf
TMPCONF=/etc/vsftpd/vconf/vconf.tmp
FTPBASE=/data/rpt
FTPHOST=ftphost
ROOT_UID=0

#Run as root.
if  [ "$EUID" -ne "$ROOT_UID" ];then
	echo "Must be root to run this script."
	exit 87
fi

#Need two parameters.
if [ $# != 2 ];then
    echo "Usage: $0 {filepath} {center code}" >&2
    exit 1
fi

#Make sure #FTPHOST user not exist.
if id -u $FTPHOST >/dev/null 2>&1; then
	echo "$FTPHOST user exists, please change '$FTPHOST' in shell to another user."
	exit 1
fi

set -e
#Setup logging
#Logs stderr and stdout to separate files.
exec 2> >(tee "./vsftpd_init_$$.err")
exec > >(tee "./vsftpd_init_$$.log")

#Install required commands.
if [ $(rpm -qa | grep vsftpd | wc -l) -eq 0 ]; then
	rpm -ivh vsftpd-*
fi

if [ $(rpm -qa | grep pam | wc -l) -eq 0 ]; then
	rpm -ivh pam-*
fi

if [ $(rpm -qa | grep db4-utils | wc -l) -eq 0 ]; then
	rpm -ivh db4-utils*
fi

#Remove possible msdos/windows carriage returns from file.
sed -i 's/\r//g' $1

#Remove possible empty lines from file.
sed -i 's/^$/d/g' $1

#Make FTPBASE directory
if [ ! -d $FTPBASE ]; then
	mkdir $FTPBASE -p
fi

useradd -d $FTPBASE -s /sbin/nologin $FTPHOST
if [ -f "/etc/vsftpd/vsftpd.conf" ]; then
	mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak.$(date +%Y%m%d)
fi

cat > /etc/vsftpd/vsftpd.conf << EOF
anonymous_enable=NO
#设定不允许匿名访问

local_enable=YES
#设定本地用户可以访问。注意：主要是为虚拟宿主用户，如果该项目设定为NO那么所有虚拟用户将无法访问。

write_enable=YES
#设定可以进行写操作。

local_umask=022
#设定上传后文件的权限掩码。

anon_upload_enable=NO
#禁止匿名用户上传。

anon_mkdir_write_enable=NO
#禁止匿名用户建立目录。

dirmessage_enable=YES
#设定开启目录标语功能。

xferlog_enable=YES
#设定开启日志记录功能。

connect_from_port_20=YES
#设定端口20进行数据连接。

chown_uploads=NO
#设定禁止上传文件更改宿主。

xferlog_file=/var/log/vsftpd.log
#设定Vsftpd的服务日志保存路径。

xferlog_std_format=YES
#设定日志使用标准的记录格式。

idle_session_timeout=600
#设定空闲连接超时时间，这里使用默认，单位秒。

#data_connection_timeout=120
#设定单次最大连续传输时间，这里使用默认。将具体数值留给每个具体用户具体指定，当然如果不指定的话，还是使用这里的默认值120，单位秒。

async_abor_enable=YES
#设定支持异步传输功能。

ascii_upload_enable=YES
ascii_download_enable=YES
#设定支持ASCII模式的上传和下载功能。

ftpd_banner=$FTPBANNER
#设定Vsftpd的登陆标语。

chroot_local_user=YES
#禁止本地用户登出自己的FTP主目录

chroot_list_enable=YES
#禁止用户登出自己的FTP主目录。
# (default follows)
chroot_list_file=/etc/vsftpd/chroot_list
#在chroot_list文件中可设置部分特殊用户能够登出自己的FTP主目录

ls_recurse_enable=NO
#禁止用户登陆FTP后使用"ls -R"的命令。该命令会对服务器性能造成巨大开销。如果该项被允许，那么挡多用户同时使用该命令时将会对该服务器造成威胁。

listen=YES
#设定该Vsftpd服务工作在StandAlone模式下。

pam_service_name=vsftpd
#设定PAM服务下Vsftpd的验证配置文件名。因此，PAM验证将参考/etc/pam.d/下的vsftpd文件配置。

userlist_enable=YES
#设定userlist_file中的用户将不得使用FTP。

tcp_wrappers=YES
#设定支持TCP Wrappers。

#以下是关于Vsftpd虚拟用户的重要配置项目，默认没有，需要自己手动添加配置。
guest_enable=YES
#设定启用虚拟用户功能。
guest_username=$FTPHOST
#指定虚拟用户的宿主用户。
virtual_use_local_privs=YES
#设定虚拟用户的权限符合他们的宿主用户。
user_config_dir=$CONFBASE
#设定虚拟用户个人Vsftp的配置文件存放路径。目录中将存放每个Vsftp虚拟用户的个性配置文件，配置文件名必须和虚拟用户名相同。
EOF

touch /var/log/vsftpd.log
touch /etc/vsftpd/chroot_list
touch /etc/vsftpd/user_list
mkdir $CONFBASE -p
#rm $USERFILE
touch $USERFILE
mv /etc/pam.d/vsftpd /etc/pam.d/vsftpd.bak.$(date +%Y%m%d)

cat  > /etc/pam.d/vsftpd << EOF
#%PAM-1.0
auth       sufficient   pam_userdb.so     db=$USERFILE
account    sufficient   pam_userdb.so     db=$USERFILE
#这里选择sufficient而不是required的原因是，sufficient表示充分条件，可以让vsftpd同时支持虚拟用户和本地用户。
session    optional     pam_keyinit.so    force revoke
auth       required     pam_listfile.so item=user sense=deny file=/etc/vsftpd/ftpusers onerr=succeed
auth       required     pam_shells.so
auth       include      system-auth
account    include      system-auth
session    include      system-auth
session    required     pam_loginuid.so
EOF

cat  > $TMPCONF << EOF
local_root=$FTPBASE/virtuser
#指定虚拟用户的具体主路径。
anonymous_enable=NO
#设定不允许匿名用户访问。
write_enable=YES
#设定允许写操作。
local_umask=022
#设定上传文件权限掩码。
anon_upload_enable=NO
#设定不允许匿名用户上传。
anon_mkdir_write_enable=NO
#设定不允许匿名用户建立目录。
#cmds_denied=DELE,RMD
#禁止用户删除文件
#idle_session_timeout=600
#设定空闲连接超时时间。
#data_connection_timeout=120
#设定单次连续传输最大时间。
#max_clients=10
#设定并发客户端访问个数。
#max_per_ip=5
#设定单个客户端的最大线程数，这个配置主要来照顾Flashget、迅雷等多线程下载软件。
#local_max_rate=50000
#设定该用户的最大传输速率，单位b/s。

EOF

while read line; do
	#Write the username and password to $USERFILE
	USERNAME=$(echo $line | cut -d ":" -f1)
	PASSWORD=$(echo $line | cut -d ":" -f2)
	echo $USERNAME >> $USERFILE
	echo $PASSWORD >> $USERFILE
	#Create the configure file of virtual user
	cp $TMPCONF $CONFBASE/$USERNAME
	USER1=$(echo | awk '{print substr("'${USERNAME}'",1,2)}')
	USER2=$(echo | awk '{print substr("'${USERNAME}'",3,6)}')
	#Replace the home directory name of virtual user
	sed -i "s/virtuser/$USER1\/$2\/$USER2/g" $CONFBASE/$USERNAME
	#Create the home directory of virtual user
	mkdir $FTPBASE/$USER1/$2/$USER2 -p
done < $1

rm -f $USERDB
#Generate the virtual user db
db_load -T -t hash -f $USERFILE $USERDB
#Change the owner of home directory to OS user $FTPHOST
chown -R $FTPHOST:$FTPHOST $FTPBASE
chmod 600 $USERFILE
chmod 600 $USERDB

/etc/init.d/vsftpd restart
chkconfig vsftpd on

echo "Good job, everything works!"

exit 0