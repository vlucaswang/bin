#!/bin/sh
if [ -n "$1" ]; then
	ifconfig $1|awk -F'[ :]+''/inet addr/{print $4}'
else
	echo "No parameter detected, echo default eth0"
	ifconfig eth0|awk -F'[ :]+''/inet addr/{print $4}'
fi

exit0
