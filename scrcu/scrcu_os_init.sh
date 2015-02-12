#!/bin/bash

#########################################
#Function:    init scrcu rhel/suse os
#Usage:       bash scrcu_os_init.sh
#Author:      Xiaochuan Wang
#Company:     SYSSSC
#Version:     1.3
#########################################

check_os_release()
{
  while true
  do
    os_release=$(grep "Red Hat Enterprise Linux Server release" /etc/issue 2>/dev/null)
    os_release_2=$(grep "Red Hat Enterprise Linux Server release" /etc/redhat-release 2>/dev/null)
    if [ "$os_release" ] && [ "$os_release_2" ]
    then
      if echo "$os_release"|grep "release 5" >/dev/null 2>&1
      then
        os_release=redhat5
        os_type=redhat
        echo "$os_release"
      elif echo "$os_release"|grep "release 6" >/dev/null 2>&1
      then
        os_release=redhat6
        os_type=redhat
        echo "$os_release"
      else
        os_release=""
        echo "$os_release"
      fi
      break
    fi
    os_release=$(grep -i "suse" /etc/issue 2>/dev/null)
    os_release_2=$(grep -i "suse" /etc/SuSE-release 2>/dev/null)
    if [ "$os_release" ] && [ "$os_release_2" ]
    then
      if echo "$os_release"|grep "Server 10" >/dev/null 2>&1
      then
        os_release=suse10
        os_type=suse
        echo "$os_release"
      elif echo "$os_release"|grep "Server 11" >/dev/null 2>&1
      then
        os_release=suse11
        os_type=suse
        echo "$os_release"
      else
        os_release=""
        echo "$os_release"
      fi
      break
    fi
    break
    done
}

modify_rhel5_yum()
{
  if [ ! -f /etc/yum.repos.d/rhel6x64.repo ]
  then
    wget -O /etc/yum.repos.d/rhel5x64.repo http://10.128.128.103/rhel5x64.repo
    yum clean metadata
    yum makecache
    cd ~
  fi
}

modify_rhel6_yum()
{
  if [ ! -f /etc/yum.repos.d/rhel6x64.repo ]
  then
    wget -O /etc/yum.repos.d/rhel6x64.repo http://10.128.128.103/rhel6x64.repo
    yum clean metadata
    yum makecache
    cd ~
  fi
}

config_time_zone()
{
  if [ "$os_type" == "redhat" ]
  then
    if [ -e "/usr/share/zoneinfo/Asia/Shanghai" ]
    then
      echo -e "\033[40;32mStep1:Begin to config time zone.\n\033[40;37m"
      cp -fp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
      echo -e "ZONE=\"Asia/Shanghai\"\nUTC=false\nARC=false">/etc/sysconfig/clock
    fi
  fi
}

install_ntp()
{
  case "$os_release" in
  redhat5)
    modify_rhel5_yum
    if ! yum install ntp -y >/dev/null 2>&1
    then
      echo "Can not install ntp.Script will end."
      rm -rf $LOCKfile
      exit 1
    fi
    ;;
  redhat6)
    modify_rhel6_yum
    if ! yum install ntp -y >/dev/null 2>&1
    then
      echo "Can not install ntp.Script will end."
      rm -rf $LOCKfile
      exit 1
    fi
    ;;
 esac
}

mod_config_file()
{
  if [ "$os_type" == "redhat" ] || [ "$os_type" == "suse" ]
  then
     if ! grep "10.128.128.115" /etc/ntp/step-tickers >/dev/null 2>&1
     then
       echo -e "10.128.128.115\n10.128.128.6">>/etc/ntp/step-tickers
     fi
  fi
  if ! grep "10.128.128.115" /etc/ntp.conf >/dev/null 2>&1
  then
    sed -i.${DATE}.bak '/^server.*org/d' /etc/ntp.conf
    echo -e "server 10.128.128.115 prefer iburst\nserver 10.128.128.6">>/etc/ntp.conf
  fi
  if [ "$os_type" == "redhat" ]
  then
    chkconfig ntpd on
  elif [ "$os_type" == "suse" ]
  then
    rcconf --on ntp
  fi
}

install_db2_dependency()
{
  if [ "$os_release" == "redhat5" ]
  then
     modify_rhel5_yum
     yum install -y net-snmp lrzsz OpenIPMI pam pam.i386 libstdc++ libstdc++.i386 compat-libstdc++-33 compat-libstdc++-33.i386 libaio libaio.i386 rdma ksh binutils unixODBC unixODBC-devel compat-libcap1 glibc-devel glibc-devel.i386 libgcc libgcc.i386 libstdc++-devel libstdc++-devel.i386 libaio-devel libaio-devel.i386 make >/dev/null 2>&1
  fi
  if [ "$os_release" == "redhat6" ]
  then
     modify_rhel6_yum
     yum install -y net-snmp lrzsz OpenIPMI pam pam.i686 libstdc++ libstdc++.i686 compat-libstdc++-33 compat-libstdc++-33.i686 libaio libaio.i686 rdma ksh binutils unixODBC unixODBC-devel compat-libcap1 glibc-devel glibc-devel.i686 libgcc libgcc.i686 libstdc++-devel libstdc++-devel.i686 libaio-devel libaio-devel.i686 make >/dev/null 2>&1
  fi
  if [ "$os_type" == "redhat" ]
  then
     yum install ftp lftp vsftpd -y >/dev/null 2>&1
     chkconfig vsftpd on
     service vsftpd start
  fi
}

install_set_ulimit()
{
  cat >/etc/security/limits.conf <<EOF
  * - nofile 65536
  * - nproc 65536
EOF
  cat >/etc/security/limits.d/90-nproc.conf <<EOF
  * soft nproc 65535
  root soft nproc unlimited
EOF
  echo "ulimit -HSn 65536" >> /etc/rc.local
}

install_vncserver()
{
  if [ "$os_type" == "redhat" ]
  then
     yum install tightvnc-server -y >/dev/null 2>&1
  fi
}

config_vncserver()
{
  echo "VNCSERVERS=\"1:oracle\"" >> $VNCCONF
  echo 'VNCSERVERARGS[1]="-geometry 1024x768 -alwaysshared"' >> $VNCCONF
  mkdir -p ${USERHOME}/.vnc
  echo "oracle" | vncpasswd -f > ${USERHOME}/.vnc/passwd
  chmod 600 ${USERHOME}/.vnc/passwd
  chown -R oracle.$USERGROUP ${USERHOME}

  service vncserver start
  service vncserver stop

  sed -i.${DATE}.bak 's/twm & /gnome-session &/g' ${USERHOME}/.vnc/xstartup

  service vncserver start
  chkconfig vncserver on
}

config_hostname()
{
  hostname $1
  sed -i.${DATE}.bak "s/HOSTNAME=.*/HOSTNAME=$1/g" /etc/sysconfig/network
  echo "$(ifconfig | awk '/inet addr/{print substr($2,6)}' | grep -v 127.0) $1 $(echo $1|cut -d. -f1)" >> /etc/hosts
}

generate_rsa_key()
{
  ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
}

copy_rsa_pub_key()
{
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxYkLk08TQACpV609I1FRGtG3sjBY0a5UPX5mBeXZmyeNIQ8BmfRsZ7D7XqPueQK/dzsBNuUpNJ8/NYvXMIeantKzz5Zno9jfsLhHYzyaQjmi/CVNYyql/bhqSY0rSCA7Q+f7lKTeDr8Z6Z/ozqXkwYHnjNWqtsZD1i1z3iYDYOx1lCH3L4lXByY1C8NZNolLmiNEvOzIijWMfAZLuUM93mbCpKoRmijojyIQnk1JRqtZMhKOQ2zRPNjWOtHmicoJeK2N6FisKsXpaxKboJNRvx2nvK6kIMwRCKLB6KBaTMk05/AivmM3F1MfJqQbunVY/HfMVZc2M0mLuRyZ5mlpPQ== root@zabbixhost.scrcu.com" >> ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys
}

config_history_timestamp()
{
  cat >/etc/profile.d/hist.sh <<EOF
  HISTFILESIZE=20000
  HISTSIZE=2000
  HISTIGNORE=""
  HISTCONTROL=""
  readonly HISTFILE
  readonly HISTCMD
  readonly HISTSIZE
  readonly HISTFILESIZE
  readonly HISTIGNORE
  readonly HISTCONTROL
  PROMPT_COMMAND="\${PROMPT_COMMAND:-:} ; history -a"
  export HISTSIZE HISTFILESIZE HISTIGNORE HISTCONTROL PROMPT_COMMAND
  export HISTTIMEFORMAT="\$LOGNAME %F %T "
EOF
  shopt -s histappend
  source /etc/profile.d/hist.sh
}

config_profile_harden()
{
  find / -maxdepth 4 -name '*sh_history' -print | xargs chattr +a
}

config_fw_selinux()
{
  /etc/init.d/iptables stop
  chkconfig iptables off
  sed -i.${DATE}.bak 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0
}

config_service()
{
  export LANG="en_US.UTF-8"
  for i in `chkconfig --list |grep '3:on'|awk '{print $1}'`
  do
    chkconfig $i off
  done
  for i in acpid auditd messagebus network sshd rsyslog udev-post crond sysstat postfix ntpd
  do
    chkconfig $i on
  done
}

config_sshd()
{
  sed -i 's/^#UseDNS yes$/UseDNS no/' /etc/ssh/sshd_config
  service sshd reload
}

config_vim()
{
  cat >/root/.vimrc <<EOF
  hi Comment ctermfg =yellow
  set ts=4
  set expandtab
  set nu
  set encoding=utf-8
  set termencoding=utf-8
  set fileencoding=utf-8
  set hlsearch
  set showmatch
EOF
}

config_safey()
{
  sed -i 's/^PASS_MIN_LEN.*5$/PASS_MIN_LEN 8/g' /etc/login.defs
  sed -i 'N;/^#%PAM-1.0$/a\auth       required     pam_tally2.so onerr=fail deny=3 even_deny_root unlock_time=1200 root_unlock_time=60' /etc/pam.d/sshd
  sed -i 'N;/^account/a\account    required     pam_tally2.so' /etc/pam.d/sshd
  sed -i 's/^#PermitEmptyPasswords.*no$/PermitEmptyPasswords no/' /etc/ssh/sshd_config
  sed -i 's/^PasswordAuthentication.*yes$/PasswordAuthentication no/' /etc/ssh/sshd_config
  sed -i 's/^ChallengeResponseAuthentication.*no$/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
  service sshd reload
  chmod 600 /etc/xinetd.d/
  chmod 400 /var/log/messages
  echo 'TMOUT=300' >> /etc/profile
}

restart_ntp()
{
  if [ "$os_type" == "redhat" ]
  then
    service ntpd restart
  elif [ "$os_type" == "suse" ]
  then
    service ntp restart
  fi
}

read_hostname()
{
  read -p "请输入主机名: " HOSTNAME
}

manual_option()
{
AStr="生成ssh信任,设置ulimit,history时间戳,配置文件保护"
BStr="关闭防火墙,selinux,优化启动服务"
CStr="调整并同步NTP"
DStr="调整vim,sshd"
EStr="安全配置"
FStr="安装数据库系统依赖包"
GStr="安装配置vnc服务器"
HStr="一键初始化"
echo "+--------------------------------------------------------------+"
echo "+-----------------欢迎对系统进行初始化安全设置！---------------+"
echo "A:${AStr}"
echo "B:${BStr}"
echo "C:${CStr}"
echo "D:${DStr}"
echo "E:${EStr}"
echo "F:${FStr}"
echo "G:${GStr}"
echo "H:${HStr}"
echo "+--------------------------------------------------------------+"
echo "注意:如果没有选择初始化选项，10秒后将自动选择一键初始化安装!"
echo "+--------------------------------------------------------------+"
read -n1 -t10 -p "请选择初始化选项[A-B-C-D-E-F-G-H]:" option
option=${option:-"H"}
flag2=$(echo $option|egrep "[A-Ha-h]"|wc -l)
if [ $flag2 -ne 1 ];then
  echo -e "\n\n请重新运行脚本,输入从A--->H的字母:"
  rm -rf $LOCKfile
  exit 1
fi
echo -e "\n你选择的选项是:$option\n"
echo "5秒之后开始安装 ......"
sleep 5
}

install_option()
{
  check_os_release
  case $1 in
    A|a)
    #read_hostname
    #config_hostname $HOSTNAME
    generate_rsa_key
    copy_rsa_pub_key
    install_set_ulimit
    config_history_timestamp
    config_profile_harden
       ;;
    B|b)
    config_fw_selinux
    config_service
       ;;
    C|c)
    config_time_zone
    install_ntp
    mod_config_file
    ntpdate -u 10.128.128.115
    restart_ntp
       ;;
    D|d)
    config_vim
    config_sshd
       ;;
    E|e)
    config_safey
       ;;
    F|f)
    install_db2_dependency
       ;;
    G|g)
    install_vncserver
    config_vncserver
       ;;
    H|h)
    #read_hostname
    #config_hostname $HOSTNAME
    generate_rsa_key
    copy_rsa_pub_key
    install_set_ulimit
    config_history_timestamp
    config_profile_harden
    config_fw_selinux
    config_service
    config_time_zone
    install_ntp
    mod_config_file
    ntpdate -u 10.128.128.115
    restart_ntp
    config_vim
    config_sshd
    config_safey
    install_db2_dependency
    install_vncserver
    config_vncserver
       ;;
    *)
    echo "请输入从A--->H的字母,谢谢!"
    rm -rf $LOCKfile
    exit 1
       ;;
esac
}

####################Start###################
#check lock file ,one time only let the script run one time
LOCKfile=/tmp/.$(basename $0)
DATE=$(date +%Y%m%d)
VNCCONF=/etc/sysconfig/vncservers
USERHOME=$(grep "^oracle:" /etc/passwd | awk -F: '{print $6}')
USERGROUP=$(grep "^oracle:" /etc/passwd | awk -F: '{print $4}')

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

if [ $# -eq 1 ];then
	install_option $1
elif [ $# -eq 0 ]; then
	manual_option
	install_option $option
else
	echo "Usage: $0 {请选择初始化选项[A-B-C-D-E-F-G-H]}" >&2
	rm -rf $LOCKfile
  exit 1
fi

rm -rf $LOCKfile
echo "系统初始化完成!"
exit 0