#!/bin/bash

# put your JAVA_HOME here
JAVA_HOME=/opt/javavm

PID=$1
IFS=''
top_number=10
if [ $# -gt 1 ] ; then
  top_number=$2
fi

top_number=$((top_number+1))

java_stack=`$JAVA_HOME/bin/jstack $PID`

top=`top -s -b -H -p $PID -n 1 | grep -vE '^top|^Tasks|^Cpu|^Mem|^Swap|^$' | awk 'NR==1; NR > 1 {print $0 | "sort  -nrk 9"}' | head -$top_number`
echo $top

echo $top | while read psline; do 
  if [ `echo $psline|grep -c PID` -gt 0 ] ;  
    then continue
  fi
  lwp_id=`echo $psline | awk '{print $1}'` 
  nid=`printf '%x\n' $lwp_id ` 
  echo "========> Java LWP: $lwp_id - Native Thread ID=$nid"
  echo $java_stack | sed -n "/$nid/,/^$/ p" ;   
done