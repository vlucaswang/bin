#!/bin/bash

# Provided by Xiaochuan Wang
# xiaochuan.wang@sysssc.com
# 
# Version 1.0

export LANG=zh_CN.UTF-8
export PATH=/usr/bin:$PATH

CUSTOMER_NAME="重庆三峡银行"
CHECK_DATE="2015年4月29日"
LOG_PATH=/tmp/sysssc
LOG_FILE=`hostname`_`echo $(/sbin/ifconfig | awk '/inet addr/{print substr($2,6)}' | grep -v 127.0) | sed "s/ /_/g"`
LOCKfile=.$(basename $0).lock

DATA_TIME=10
ALERT=80

# Run as root.
if  [ "$EUID" -ne 0 ];then
	echo "需要Root用户运行此脚本。"
	exit 87
fi

if [ -f "$LOCKfile" ]
then
  echo "脚本正在运行中，请稍等。"
  exit 2
else
  echo "脚本启动中。"
  touch $LOCKfile
fi

rm -rf ${LOG_PATH}
# Create directory for outputs.
if [ ! -d ${LOG_PATH} ]
then
	mkdir -p ${LOG_PATH}
fi

#echo "主机名,IP,服务器厂商,型号,序列号,CPU,内存,操作系统版本,内核版本,空闲文件系统是否紧张,inode是否禁止,\
#swap是否紧张,时区是否正常,ntp是否正常,crontab是否正常,15分钟负载均值,阻塞线程均值,阻塞线程最大值,\
#iowait均值, iowait最大值,time_wait值,主机名设置是否正常,kdump是否正常,iptables是否正常,selinux是否正常,\
#ulimit是否正常,secure日志是否正常,boot.log日志是否正常,messages日志是否正常,dmesg日志是否正常" >> $LOG_PATH/$LOG_FILE.csv

check_header() {
	sys_ip=$(echo `ip a | awk '/inet / {print $2}' | grep -v ^127`)
	echo "Linux系统巡检报告单"
	echo "客户名称：" $CUSTOMER_NAME " 检查时间：" $CHECK_DATE
	echo "系统名称：" $(hostname) " 系统IP：" $sys_ip
	echo "服务编号：" " 合同编号："
	echo ""

	echo -n $(hostname),$sys_ip, >> $LOG_PATH/$LOG_FILE.csv
}

get_nr_processor() {
    grep '^processor' /proc/cpuinfo | wc -l
}

get_nr_socket() {
    grep 'physical id' /proc/cpuinfo | awk -F: '{print $2 | "sort -un"}' | wc -l
}

get_nr_cores_of_socket() {
    grep 'cpu cores' /proc/cpuinfo | awk -F: '{print $2 | "sort -un"}'
}

get_nr_model() {
	awk -F: '/model name/{print $2}' /proc/cpuinfo
}

check_cpu() {
	nr_socket=`get_nr_socket`
	echo -n $nr_socket"插槽 "

	nr_processor=`get_nr_processor`
	echo -n $nr_processor"核 "

	nr_cores=`get_nr_cores_of_socket`

	let nr_cores*=nr_socket
	echo -n $nr_cores"线程 "
	echo -n $nr_cores, >> $LOG_PATH/$LOG_FILE.csv

	nr_model=`get_nr_model`
	echo "CPU型号： " $nr_model
}

check_pci() {
	while read line;do
		nic_name=$(echo $line|awk '{for(i=2;i<=NF;i++) printf $i" "}')
		nic_num=$(echo $line|awk '{print $1}')
		echo $nic_name"/"$nic_num"个"
	done
}

check_hardware() {
	hw_vendor=$(dmidecode -t 1|awk -F: '/Manufacturer/ {print $2}'|awk -F, '{print $1}')
	hw_model=$(dmidecode -t 1|awk -F: '/Product Name/ {print $2}')
	hw_serial=$(dmidecode -t 1|awk -F: '/Serial Number/ {print $2}')
	hw_memory=$(dmidecode -t 17 | grep "Size.*MB" | awk '{s+=$2} END {print s/1024,"GB"}')
	echo "一、系统硬件配置："
	echo ""
	echo "1.服务器厂商：" $hw_vendor " 型号：" $hw_model
	echo " 序列号：" $hw_serial
	echo -n $hw_vendor,$hw_model,$hw_serial, >> $LOG_PATH/$LOG_FILE.csv
	echo "2.CPU配置："
	check_cpu
	echo "3.内存配置：" $hw_memory
	echo "4.HBA卡型号/数量："
	lspci|awk -F: '/Fibre Channel/ {print $3}'|sort|uniq -c|sort -k1,1nr|check_pci
	echo "5.网口型号/数量："
	lspci|awk -F: '/Ethernet/ {print $3}'|sort|uniq -c|sort -k1,1nr|check_pci
	#echo "6.RAID信息："
	#lspci|awk -F: '/RAID/ {print $3}'|sort|uniq -c|sort -k1,nr|check_pci
	#cat /proc/scsi/scsi

	echo -n $hw_memory, >> $LOG_PATH/$LOG_FILE.csv
}

check_fs() {
	while read line; do
	  util=$(echo $line | awk '{print $1}' | cut -d'%' -f1)
	  fs=$(echo $line | awk '{print $2}')
	  space=$(echo $line | awk '{print $3}')
	  err="0"
	  if [ ! "$util" == "" ]; then
	  	if [ $util -ge $ALERT ]; then
	    	echo $fs"文件系统空间紧张，"$util"%空间已被占用，剩余"$space"，需及时清理空间。"
	    	err="1"
		else
			echo $fs"文件系统空间占用正常，低于"$ALERT"%。"
	  	fi
	  fi
	done
	echo -n "$err", >> $LOG_PATH/$LOG_FILE.csv
}

check_fs_inode() {
	while read line; do
	  util=$(echo $line | awk '{print $1}' | cut -d'%' -f1)
	  fs=$(echo $line | awk '{print $2}')
	  space=$(echo $line | awk '{print $3}')
	  err="0"
	  if [ ! "$util" == "" ]; then
	  	if [ $util -ge $ALERT ]; then
	    	echo $fs"文件系统inode紧张，"$util"%inode已被占用，剩余"$space"，需及时清理inode。"
	    	err="1"
		else
			echo $fs"文件系统inode占用正常，低于"$ALERT"%。"
	  	fi
	  fi
	done
	echo -n "$err", >> $LOG_PATH/$LOG_FILE.csv
}

check_swap() {
	util=$(swapon -s|awk '/^[^F ]/ {print int($4/$3)}')
	err="0"
	if [ ! "$util" == "" ]; then
	  if [ $util -ge $ALERT ]; then
	    echo "swap交换区紧张，"$util"%swap已被使用。"
	    err="1"
	  else
		echo "swap交换区占用正常，低于"$ALERT"%。"
	  fi
	fi
	echo -n "$err", >> $LOG_PATH/$LOG_FILE.csv
}

check_timezone() {
	err="0"
	grep -E "Shanghai|Chongqing" /etc/sysconfig/clock >/dev/null 2>&1
	if [ "$?" -gt "0" ]; then
		err="1"
		echo "时区设置不正常，请检查。"
	else
		echo "时区设置正常。"
	fi
	echo -n "$err", >> $LOG_PATH/$LOG_FILE.csv
}

check_ntp() {
	service_name="ntp"
	err="0"
	for ip in $(awk '/^server/ {print $2}' /etc/ntp.conf); do
		ping -c 1 -w 1 $ip >/dev/null 2>&1
		if [ "$?" -gt "0" ]; then
			err="1"
		fi
	done
	ps -ef | grep -Ev "grep|check" | grep $service_name >/dev/null 2>&1
	if [ "$?" -gt "0" ]; then
		err="1"
		echo "NTP未运行或无法ping通ntp服务器，请检查。"
	else
		echo "NTP运行正常。"
	fi
	echo -n "$err", >> $LOG_PATH/$LOG_FILE.csv
}

check_crontab_full() {
	# System-wide crontab file and cron job directory. Change these for your system.
	CRONTAB='/etc/crontab'
	CRONDIR='/etc/cron.d'
	
	# Single tab character. Annoyingly necessary.
	tab=$(echo -en "\t")
	
	# Given a stream of crontab lines, exclude non-cron job lines, replace
	# whitespace characters with a single space, and remove any spaces from the
	# beginning of each line.
	clean_cron_lines() {
	    while read line; do
	        echo "${line}" |
	            egrep --invert-match '^($|\s*#|\s*[[:alnum:]_]+=)' |
	            sed --regexp-extended "s/\s+/ /g" |
	            sed --regexp-extended "s/^ //"
	    done;
	}
	
	# Given a stream of cleaned crontab lines, echo any that don't include the
	# run-parts command, and for those that do, show each job file in the run-parts
	# directory as if it were scheduled explicitly.
	lookup_run_parts() {
	    while read line; do
	        match=$(echo "${line}" | egrep -o 'run-parts (-{1,2}\S+ )*\S+')
	 
	        if [[ -z "${match}" ]]; then
	            echo "${line}"
	        else
	            cron_fields=$(echo "${line}" | cut -f1-6 -d' ')
	            cron_job_dir=$(echo  "${match}" | awk '{print $NF}')
	 
	            if [[ -d "${cron_job_dir}" ]]; then
	                for cron_job_file in "${cron_job_dir}"/*; do  # */ <not a comment>
	                    [[ -f "${cron_job_file}" ]] && echo "${cron_fields} ${cron_job_file}"
	                done
	            fi
	        fi
	    done;
	}
	
	# Temporary file for crontab lines.
	temp=$(mktemp) || exit 1
	
	# Add all of the jobs from the system-wide crontab file.
	cat "${CRONTAB}" | clean_cron_lines | lookup_run_parts >"${temp}" 
	
	# Add all of the jobs from the system-wide cron directory.
	cat "${CRONDIR}"/* | clean_cron_lines >>"${temp}"  # */ <not a comment>

	# Hourly, Daily, Weekly and Monthly scripts
	CRONDIR_HOURLY='/etc/cron.hourly'
	CRONDIR_DAILY='/etc/cron.daily'
	CRONDIR_WEEKLY='/etc/cron.weekly'
	CRONDIR_MONTHLY='/etc/cron.monthly'

	ls -lR "${CRONDIR_HOURLY}" | grep "^-" | awk -v dir="${CRONDIR_HOURLY}" {'print "01 * * * * root "dir"/" $9'} >>"${temp}"
	ls -lR "${CRONDIR_DAILY}" | grep "^-" | awk -v dir="${CRONDIR_DAILY}" {'print "02 4 * * * root "dir"/" $9'} >>"${temp}"
	ls -lR "${CRONDIR_WEEKLY}" | grep "^-" | awk -v dir="${CRONDIR_WEEKLY}" {'print "22 4 * * 0 root "dir"/" $9'} >>"${temp}"
	ls -lR "${CRONDIR_MONTHLY}" | grep "^-" | awk -v dir="${CRONDIR_MONTHLY}" {'print "42 4 1 * * root "dir"/" $9'} >>"${temp}"
	
	# Add each user's crontab (if it exists). Insert the user's name between the
	# five time fields and the command.
	while read user ; do
	    crontab -l -u "${user}" 2>/dev/null |
	        clean_cron_lines |
	        sed --regexp-extended "s/^((\S+ +){5})(.+)$/\1${user} \3/" >>"${temp}"
	done < <((cut --fields=1 --delimiter=: /etc/passwd && find /home/ -maxdepth 1 -mindepth 1 -type d -printf "%f\n") | sort | uniq)

	# Output the collected crontab lines. Replace the single spaces between the
	# fields with tab characters, sort the lines by hour and minute, insert the
	# header line, and format the results as a table.
	cat "${temp}" |
	    sed --regexp-extended "s/^(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(.*)$/\1\t\2\t\3\t\4\t\5\t\6\t\7/" |
	    sort --numeric-sort --field-separator="${tab}" --key=2,1 |
	    sed "1i\mi\th\td\tm\tw\tuser\tcommand" |
	    column -s"${tab}" -t
	
	rm --force "${temp}"
}

check_crontab_lite() {
	cron_num=$(for i in `ls -1 /var/spool/cron/`;do cat /var/spool/cron/$i;done|wc -l)
	err="0"
	if [ ! "$cron_num" == "" ]; then
	  if [ $cron_num -gt "0" ]; then
	    echo "crontab有"$cron_num"个定时任务在运行，需要关注。"
	    err="1"
	  else
		echo "没有crontab定时任务运行。"
	  fi
	fi
	echo -n "$err", >> $LOG_PATH/$LOG_FILE.csv
	check_crontab_full >> $LOG_PATH/$LOG_FILE.log
}

check_os() {
	os_version=$(head -1 /etc/issue)
	os_kernel_version=$(uname -r)
	echo "二、系统状态及逻辑卷、文件系统检查："
	echo ""
	echo "1.操作系统版本：" $os_version " 内核版本：" $os_kernel_version
	echo -n $os_version,$os_kernel_version, >> $LOG_PATH/$LOG_FILE.csv
	echo "2.文件系统检查，并向用户提出改进建议："
	df -hP | grep -vE "^[^/]|tmpfs|cdrom|sr" | awk '{print $5" "$6" "$4}' | check_fs
	df -iP | grep -vE "^[^/]|tmpfs|cdrom|sr" | awk '{print $5" "$6" "$4}' | check_fs_inode
	echo "3.内存交换区是否正常："
	check_swap
	echo "4.时区变量及NTP是否正确："
	check_timezone
	check_ntp
	echo "5.crontab中的设置是否正常："
	check_crontab_lite
}

cat /etc/fstab >> $LOG_PATH/$LOG_FILE.log
df -hP >> $LOG_PATH/$LOG_FILE.log 2>&1
fdisk -l >> $LOG_PATH/$LOG_FILE.log 2>&1
pvs >> $LOG_PATH/$LOG_FILE.log 2>&1
vgs >> $LOG_PATH/$LOG_FILE.log 2>&1
lvs >> $LOG_PATH/$LOG_FILE.log 2>&1
top_log=${LOG_PATH}/${LOG_FILE}_top.log
top -bn $DATA_TIME > $top_log
vmstat_log=${LOG_PATH}/${LOG_FILE}_vmstat.log
vmstat 1 $DATA_TIME > $vmstat_log
iostat_log=${LOG_PATH}/${LOG_FILE}_iostat.log
iostat -kx 1 $DATA_TIME > $iostat_log
messages_log=${LOG_PATH}/${LOG_FILE}_messages.log
cat /var/log/messages* > $messages_log

check_load_perf() {
	nr_thread=`grep -c 'model name' /proc/cpuinfo`
	#load1min=$(awk '{print $1}' /proc/loadavg)
	#load5min=$(awk '{print $2}' /proc/loadavg)
	load15min=$(awk '{print $3}' /proc/loadavg)
	if [ $(echo "$load15min > $nr_thread" | bc) -eq 1 ]; then
		echo "负载均值高于"$nr_thread"，需立刻检查。"
	else
		echo "负载值低于"$nr_thread"，正常。"
	fi
	echo -n $load15min, >> $LOG_PATH/$LOG_FILE.csv
}

check_IOblock_perf() {
	nr_thread=`grep -c 'model name' /proc/cpuinfo`
	blockavg=$(sed -n '3,13p' $vmstat_log|awk '{sum+=$2} END {print sum/NR }')
	blockmax=$(sed -n '3,13p' $vmstat_log|awk '{print $2 }' |sort -n|tail -n1)
	if [ $(echo "$blockavg > $nr_thread" | bc) -eq 1 ]; then
		echo "block均值高于"$nr_thread"，需立刻检查。"
	elif [ $(echo "$blockmax > $nr_thread" | bc) -eq 1 ]; then
		echo "block最大值值高于"$nr_thread"，需密切关注。"
	else
		echo "block值为0，正常。"
	fi
	echo -n $blockavg,$blockmax, >> $LOG_PATH/$LOG_FILE.csv
}

check_IOwait_perf() {
	IOalert=40
	IOavg=$(sed -n '3,13p' $vmstat_log|awk '{sum+=$16} END {print sum/NR }')
	IOmax=$(sed -n '3,13p' $vmstat_log|awk '{print $16 }' |sort -n|tail -n1)
	if [ $(echo "$IOavg > $IOalert" | bc) -eq 1 ]; then
		echo "IOwait均值高于"$IOalert"%，需立刻检查。"
	elif [ $(echo "$IOmax > $IOalert" | bc) -eq 1 ]; then
		echo "IOwait最大值值高于"$IOalert"%，需密切关注。"
	else
		echo "IOwait值低于"$IOalert"%，正常。"
	fi
	echo -n $IOavg,$IOmax, >> $LOG_PATH/$LOG_FILE.csv
}

check_network_timewait() {
	timewait_std=10000
	timewait=$(netstat -an|awk '/ESTABLISHED/ {print $6}'|sort|uniq -c|awk '{print $1}')
	if [ "$timewait" -ge "$timewait_std" ]; then
		echo "timewait高于10000，需立刻检查。"
	else
		echo "timewait值正常。"
	fi
	echo -n $timewait, >> $LOG_PATH/$LOG_FILE.csv
}

check_perf() {
	echo "三、系统性能检查："
	echo ""
	echo "1.系统负载检查："
	check_load_perf
	echo "2.系统IO检查："
	check_IOblock_perf
	check_IOwait_perf
	echo "3.系统网络timewait检查："
	check_network_timewait
}

check_hostname() {
	hostname1=$(hostname -f)
	hostname2=$(awk '!/localhost/ {print $2}' /etc/hosts)
	hostname3=$(awk -F= '/HOSTNAME/ {print $2}' /etc/sysconfig/network)
	if [ "$hostname1" = "hostname2" ] && [ "$hostname1" = "hostname3" ]; then
		echo "主机名设置正常。"
		echo -n "0," >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "主机名设置不正常，请检查hostname、/etc/hosts、/etc/sysconfig/network。"
		echo -n "1," >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_kdump() {
	service kdump status >/dev/null 2>&1
	if [ "$?" -ne "0" ]; then
		echo "kdump无法启动，请检查。"
		echo -n "1," >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "kdump正常。"
		echo -n "0," >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_iptables() {
	service iptables status >/dev/null 2>&1
	if [ "$?" -eq "0" ]; then
		echo "iptables已开启，请检查。"
		echo -n "1," >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "iptables未开启，正常。"
		echo -n "0," >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_selinux() {
	getenforce >/dev/null 2>&1
	if [ "$?" -ne "0" ]; then
		echo "selinux已开启，请检查。"
		echo -n "1," >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "selinux未开启，正常。"
		echo -n "0," >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_file_ulimit() {
	file_ulimit=$(ulimit -a|awk '/open/ {print $4}')
	if [ "$file_ulimit" -eq "1024" ]; then
		echo "ulimit未优化，请检查。"
		echo -n "1," >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "ulimit已优化，正常。"
		echo -n "0," >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_conf() {
	echo "四、系统配置检查："
	echo ""
	echo "1.主机名检查："
	check_hostname
	echo "2.kdump检查："
	check_kdump
	echo "3.iptables检查："
	check_iptables
	echo "4.selinux检查："
	check_selinux
	echo "5.ulimt检查："
	check_file_ulimit
}

check_login() {
	while read line;do
		login_user=$(echo $line|awk '{printf $2}')
		login_ip=$(echo $line|awk '{printf $3}')
		login_frequency=$(echo $line|awk '{print $1}')
		echo "用户："$login_user"，IP："$login_ip"，登录："$login_frequency"次。"
	done
}

check_secure_log() {
	egrep 'failed | Invalid | disabled | not | warning | err' /var/log/secure  >> $LOG_PATH/$LOG_FILE.log
	if [ "$?" -eq "0" ]; then
		echo "secure日志包含危险项，请检查。"
		echo -n "1," >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "secure日志正常。"
		echo -n "0," >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_boot_log() {
	egrep 'failed | Invalid | disabled | not | warning | err' /var/log/boot.log  >> $LOG_PATH/$LOG_FILE.log
	if [ "$?" -eq "0" ]; then
		echo "boot.log日志包含危险项，请检查。"
		echo -n "1," >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "boot.log日志正常。"
		echo -n "0," >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_messages_log() {
	egrep 'failed | Invalid | disabled | not | warning | err' /var/log/messages  >> $LOG_PATH/$LOG_FILE.log
	if [ "$?" -eq "0" ]; then
		echo "messages日志包含危险项，请检查。"
		echo -n "1," >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "messages日志正常。"
		echo -n "0," >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_dmesg_log() {
	egrep 'failed | Invalid | disabled | not | warning | err' /var/log/dmesg  >> $LOG_PATH/$LOG_FILE.log
	if [ "$?" -eq "0" ]; then
		echo "dmesg日志包含危险项，请检查。"
		echo "1" >> $LOG_PATH/$LOG_FILE.csv
	else
		echo "dmesg日志正常。"
		echo "0" >> $LOG_PATH/$LOG_FILE.csv
	fi
}

check_chkconfig() {
	chkconfig --list >> $LOG_PATH/$LOG_FILE.log
}

check_security() {
	echo "五、系统安全检查："
	echo ""
	echo "1.登录检查："
	last -100 -i|grep pts|awk '{print $1,$3}'|sort|uniq -c|sort -r|head -3|check_login
	echo "2.登录失败检查："
	lastb -i|awk 'NF==10 {print $1,$3}'|sort|uniq -c|sort -r|check_login
	echo "3.安全日志检查："
	check_secure_log
	echo "4.启动日志检查："
	check_boot_log
	echo "5.系统日志检查："
	check_messages_log
	echo "6.硬件日志检查："
	check_dmesg_log

	check_chkconfig
}

for i in check_header check_hardware check_os check_perf check_conf check_security
do
	$i
	echo ""
done | tee $LOG_PATH/$LOG_FILE.doc

# CSV
# 主机名,IP,服务器厂商,型号,序列号,CPU,内存,操作系统版本,内核版本,空闲文件系统是否紧张,inode是否禁止,\
# swap是否紧张,时区是否正常,ntp是否正常,crontab是否正常,15分钟负载均值,阻塞线程均值,阻塞线程最大值,\
# iowait均值, iowait最大值,time_wait值,主机名设置是否正常,kdump是否正常,iptables是否正常,selinux是否正常,\
# ulimit是否正常,secure日志是否正常,boot.log日志是否正常,messages日志是否正常,dmesg日志是否正常

echo "巡检成功！"

rm -rf $LOCKfile

exit 0