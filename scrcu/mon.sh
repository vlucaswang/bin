#!/bin/sh
#====================================================================
# Need to monitor the service name
# Must be in /etc/init.d folder exists(not)
NAME_LIST="runs mysqld"

# Single process to allow the maximum CPU (%)
PID_CPU_MAX="20"

# The maximum allowed memory (%)
PID_MEM_SUM_MAX="95"

# The maximum allowed system load
SYS_LOAD_MAX="24"

# Date time format setting
DATA_TIME=$(date +"%y-%m-%d %H:%M:%S")

# Log path settings
LOG_PATH="/var/log/sys-mon.$(date +%Y%m%d).log"

# Your email address
EMAIL="abs"

#====================================================================

for NAME in $NAME_LIST
do
    PID_CPU_SUM="0";PID_MEM_SUM="0"
    PID_LIST=`ps aux | grep $NAME | grep -v grep`

    IFS_TMP="$IFS";IFS=$'\n'
    for PID in $PID_LIST
    do
        PID_NUM=`echo $PID | awk '{print $2}'`
        PID_CPU=`echo $PID | awk '{print $3}'`
        PID_MEM=`echo $PID | awk '{print $4}'`
#       echo "$NAME: PID_NUM($PID_NUM) PID_CPU($PID_CPU) PID_MEM($PID_MEM)"

        PID_CPU_SUM=`echo "$PID_CPU_SUM + $PID_CPU" | bc`
        PID_MEM_SUM=`echo "$PID_MEM_SUM + $PID_MEM" | bc`

        if [ `echo "$PID_CPU >= $PID_CPU_MAX" | bc` -eq 1 ];then
            echo "${DATA_TIME}: [WARNING!] ${NAME}($PID_NUM) cpu usage is too high! (CPU:$PID_CPU)" | tee -a $LOG_PATH
        fi
    done
    IFS="$IFS_TMP"
done

    SYS_LOAD=`uptime | awk '{print $(NF-2)}' | sed 's/,//'`
    SYS_MON="CPU:$PID_CPU_SUM MEM:$PID_MEM_SUM LOAD:$SYS_LOAD"
#   echo -e "$NAME: $SYS_MON\n"

    SYS_LOAD_TOO_HIGH=`awk 'BEGIN{print('$SYS_LOAD'>'$SYS_LOAD_MAX')}'`
    PID_MEM_SUM_TOO_HIGH=`awk 'BEGIN{print('$PID_MEM_SUM'>'$PID_MEM_SUM_MAX')}'`

    if [[ "$SYS_LOAD_TOO_HIGH" = "1" || "$PID_MEM_SUM_TOO_HIGH" = "1" ]];then
        echo "${DATA_TIME}: [WARNING!] system load is too high! ($SYS_MON)" | tee -a $LOG_PATH
    fi

exit 0
