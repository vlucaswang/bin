#! /bin/sh

find /home/test1 /home/test -maxdepth 1 -name "201*" -type d -ctime +30 -exec rm -rf {} \;
