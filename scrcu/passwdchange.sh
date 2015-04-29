#!/bin/bash

PASSWD=

while read line; do
  ssh -n $line 'echo sierra | passwd --stdin root'
  ssh $line 2>&1 >result.txt << EOF
    for i in $(awk -F: '{if ($3 >= 500) { print $1 } }' /etc/passwd)
    do 
       echo $PASSWD | passwd --stdin $i
    done
  EOF
done < ip.txt