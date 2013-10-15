#!/bin/bash
POS=15
echo -n "Doing ... "
for((i=0;i<=100;i++))
do
echo -en "\\033[${POS}G $i % completed" 
sleep 0.1
done
echo -ne "\n"
