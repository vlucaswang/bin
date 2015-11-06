#!/bin/bash

KILL_PROC="$1"
KILL_PID=`ps -ef | grep -i $KILL_PROC | grep -v $(basename $0) | grep -v grep | grep -v ps | awk '{print $2}'`

if [ ! -z "$KILL_PID" ];then
    for pid in $KILL_PID
    do
        echo kill $pid
        kill -9 $pid
    done
else
    echo no $KILL_PROC found!
fi

exit 0