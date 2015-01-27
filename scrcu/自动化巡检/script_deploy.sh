#!/bin/sh

#command="sh /root/ntpcheck.sh"
#job="0 6 * * * $command"
#file="/root/ansible/tmphost3"
ROOT_UID=0
DEFAULT_IP_LIST="/root/ansible/hosts_20150114"
INPUT_IP_LIST=$2
IP_LIST=${INPUT_IP_LIST:-DEFAULT_IP_LIST}

if [ "$EUID" -ne "$ROOT_UID" ];then
  echo "Must be root to run this script."
  exit 87
fi

if [ $# -ne 1 -a $# -ne 2 ];then
  echo "Usage: $0 {deploy|run} {iplist}" >&2
  exit 1
fi

function copy_script() {
  ssh root@$line 'rm -rf /tmp/ntp /tmp/sysssc'
  scp /root/ansible/ntpcheck.sh /root/ansible/autocheck.sh root@$line:/root/
}

run_script() {
  ssh root@$line 'LANG=C bash /root/ntpcheck.sh;LANG=C bash /root/ansible/autocheck.sh'
}

add_crontab() {
  ssh root@$line 'cat <(fgrep -i -v "ntpcheck.sh" <(crontab -l)) <(echo "44 6 * * * LANG=C /bin/bash /root/ntpcheck.sh") | crontab -'
  ssh root@$line 'cat <(fgrep -i -v "autocheck.sh" <(crontab -l)) <(echo "40 6 * * * LANG=C /bin/bash /root/autocheck.sh") | crontab -'
}

fetch_log() {
  bash /root/ansible/autocheck_get.sh
}

case "$1" in
  'deploy' )
    for line in `cat $IP_LIST |grep -v "\["|grep -v '^#' |awk '{print $1}'`
    do
      copy_script
      add_crontab
    done
    ;;

  'run' )
    for line in `cat $IP_LIST |grep -v "\["|grep -v '^#' |awk '{print $1}'`
    do
      run_script
    done
    fetch_log
    ;;
  
  *)
    echo "Usage: $0 {deploy|run} {iplist}" >&2
    exit 1
    ;;

esac

exit 0
