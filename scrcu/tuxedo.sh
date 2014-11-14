#!/bin/sh
CONF_DIR=$HOME/systembin/tuxedo/tuxmon

LDBAL=`grep LDBAL $HOME/etc/sysmng.ubb | awk 'NR==1' | awk '{print $2}'`
LMID=`grep LMID= $HOME/etc/sysmng.ubb | awk 'NR==1' | awk -F= '{print $2}'`
DOMAINID=`grep DOMAINID $HOME/etc/sysmng.ubb | awk '{print $2}'`
LOGDIR=$CONF_DIR/log

#TUXDIR=`env | grep TUXDIR | awk -F= '{print $2}'`
TUXDIR=`grep TUXDIR $HOME/etc/sysmng.ubb | awk -F "[\"\"]" '{print $2}'`
export TUXDIR

TUXCONFIG=`grep TUXCONFIG $HOME/etc/sysmng.ubb | awk -F\" '{print $2}'`
export TUXCONFIG

PATH=$PATH:$TUXDIR/bin:/sbin
export PATH

SHLIB_PATH=$SHLIB_PATH:$TUXDIR/lib
export SHLIB_PATH

LIBPATH=$LIBPATH:$TUXDIR/lib
export LIBPATH

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TUXDIR/lib
export LD_LIBRARY_PATH

TODAY=`date +%Y%m%d`
LINE="================================================================"


#caiji add env
IP=`ifconfig | grep 10.30 | awk '{print $2}' | awk -F: '{print $2}'`


#Log cpu
CPU_INFO(){
        CPU_LOG_FILENAME=$LOGDIR/cpu_log.$TODAY
        echo "#CPU start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>> $CPU_LOG_FILENAME
        vmstat 1 3|awk '{print $0}BEGIN {ln=0}{ln++;if(ln<2) next}{a=a+$15;} END{print "CPU AVERAGE Free VALUE:"a/3}'|tail -1 >> $CPU_LOG_FILENAME
        echo "#CPU end" >> $CPU_LOG_FILENAME
        echo "" >> $CPU_LOG_FILENAME
}

#Log mem
MEM_INFO(){
        MEM_LOG_FILENAME=$LOGDIR/mem_log.$TODAY
        echo "#MEM start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>> $MEM_LOG_FILENAME
        free memory -m|awk '{print $0}BEGIN {ln=0}{ln++;if(ln!=3) next}{a=$4} END{print "Memory AVERAGE Free VALUE:"a"(M)"}' >> $MEM_LOG_FILENAME
        echo "#MEM end" >> $MEM_LOG_FILENAME
        echo "" >> $MEM_LOG_FILENAME
}

#Log pclt
PCLT_INFO() {
        PCLT_LOG_FILENAME=$LOGDIR/pclt_log.$TODAY
        echo "#PCLT start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>> $PCLT_LOG_FILENAME
        echo "pclt" | tmadmin -r|grep -v "tmadmin" |awk 'BEGIN {ln=0}{ln++;if(ln<4) next}{print $0}'| grep -v \> |grep -v ^$ >> $PCLT_LOG_FILENAME
        echo "#PCLT end" >> $PCLT_LOG_FILENAME
        echo "" >> $PCLT_LOG_FILENAME
}

#Log pclt count
PCLT_COUNT_INFO() {
        PCLT_COUNT_LOG_FILENAME=$LOGDIR/pclt_count_log.$TODAY
        echo "#PCLT_COUNT start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>> $PCLT_COUNT_LOG_FILENAME
        TMPCOUNT=`echo "pclt" | tmadmin -r|grep -v "tmadmin" | wc -l`
        CLIENTCOUNT=`expr $TMPCOUNT - 5`
        echo "$CLIENTCOUNT" >> $PCLT_COUNT_LOG_FILENAME
        echo "#PCLT_COUNT end" >> $PCLT_COUNT_LOG_FILENAME
        echo "" >> $PCLT_COUNT_LOG_FILENAME
}

#Log psr
PSR_INFO() {
        PSR_FILENAME=$LOGDIR/psr_log.$TODAY
        echo "#PSR start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>> $PSR_FILENAME
        echo "psr" | tmadmin -r|awk 'BEGIN {ln=0}{ln++;if(ln<4) next}{print $0}'| grep -v \> |grep -v ^$ >> $PSR_FILENAME
        echo "#PSR end" >> $PSR_FILENAME
        echo "" >> $PSR_FILENAME
}

#Log psr count
PSR_COUNT_INFO() {
        PSR_COUNT_FILENAME=$LOGDIR/psr_count_log.$TODAY
        echo "#PSR_COUNT start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>> $PSR_COUNT_FILENAME
        TMPCOUNT=`echo "psr" | tmadmin -r| wc -l`
        PSRCOUNT=`expr $TMPCOUNT - 5`
        echo "$PSRCOUNT" >> $PSR_COUNT_FILENAME
        echo "#PSR_COUNT end" >> $PSR_COUNT_FILENAME
        echo "" >> $PSR_COUNT_FILENAME
}

#Log pq
PQ_INFO() {
        PQ_LOG_FILENAME=$LOGDIR/pq_log.$TODAY
        echo "#PQ start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>> $PQ_LOG_FILENAME
        echo "pq" | tmadmin -r |awk 'BEGIN {ln=0}{ln++;if(ln<4) next}{print $0}'| grep -v \> |grep -v ^$ >> $PQ_LOG_FILENAME
#       echo "pq" | tmadmin -r >> $PQ_LOG_FILENAME
        echo "#PQ end" >> $PQ_LOG_FILENAME
        echo "" >> $PQ_LOG_FILENAME
}

#Log pq count
PQ_COUNT_INFO() {
        PQ_COUNT_FILENAME=$LOGDIR/pq_count_log.$TODAY
        echo "#PQ_COUNT start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>> $PQ_COUNT_FILENAME
        TMPCOUNT=`echo "pq"|tmadmin -r |grep "$LMID"|grep -v "GWTDOMAIN"|awk '{pqv=pqv+$5; print pqv}'|tail -1`
        echo "$TMPCOUNT" >> $PQ_COUNT_FILENAME
        echo "#PQ_COUNT end" >> $PQ_COUNT_FILENAME
        echo "" >> $PQ_COUNT_FILENAME
}


#Log tuxedo status
TUXEDO_STATUS_INFO() {
        TUXEDO_STATUS_LOG_FILENAME=$LOGDIR/tuxedo_status_log.$TODAY
        echo "#Tuxedo_status start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>>$TUXEDO_STATUS_LOG_FILENAME
        echo "pq" | tmadmin -r | grep BBL | wc -l >> $TUXEDO_STATUS_LOG_FILENAME
        echo "#Tuxedo_status end" >> $TUXEDO_STATUS_LOG_FILENAME
        echo "" >> $TUXEDO_STATUS_LOG_FILENAME
}

#Log dom status
DOM_STATUS_INFO() {
        TUXEDO_DOM_STATUS_LOG_FILENAME=$LOGDIR/tuxedo_dom_status_log.$TODAY
        echo "#Dom_status start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>>$TUXEDO_DOM_STATUS_LOG_FILENAME
        echo "pq" | tmadmin -r | grep GWTDOMAIN | wc -l >> $TUXEDO_DOM_STATUS_LOG_FILENAME
        echo "#Dom_status end" >> $TUXEDO_DOM_STATUS_LOG_FILENAME
        echo "" >> $TUXEDO_DOM_STATUS_LOG_FILENAME
}


#Log dom
DOM_INFO() {
        DOM_LOG_FILENAME=$LOGDIR/tuxedo_dom_log.$TODAY
        echo "#Dom start" IP:$IP TIME:`date '+%Y-%m-%d %T'` LMID:$LMID DOMAINID:$DOMAINID>>$DOM_LOG_FILENAME
        echo "pd -d $DOMAINID" | dmadmin -r >> $DOM_LOG_FILENAME
        echo "#Dom end" >> $DOM_LOG_FILENAME
        echo "" >> $DOM_LOG_FILENAME
}

#Begin to Log Info

#echo "start:"`date`

for((i=1;i<=6;i++));do
CPU_INFO
MEM_INFO
PCLT_INFO
PCLT_COUNT_INFO
PSR_INFO
PSR_COUNT_INFO
PQ_INFO
PQ_COUNT_INFO
TUXEDO_STATUS_INFO
DOM_STATUS_INFO
DOM_INFO
sleep 8
done;

#echo "end:"`date`