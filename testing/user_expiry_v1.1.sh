#!/bin/bash

export LANG=zh_CN.UTF-8
export PATH=/usr/bin:$PATH

if [ ! -f /root/.ssh/id_rsa ]; then
  ssh-keygen -q -t rsa -f /root/.ssh/id_rsa -N ""
fi

cat >/root/.ssh/config <<EOF
Host *
    StrictHostKeyChecking no
EOF

while true
do
  read -p "请输入IP: " IP

  for NAME in root weblogic oracle
  do
    chage -l $NAME >/dev/null 2>&1
    if [ $(echo $?) -ne 0 ];then
      echo 用户 $NAME 不存在.
      echo ---
    else
      DAY=$(chage -l $NAME | awk -F" " /Max/'{print $9}')
      if [ "$DAY" -ne 99999 ];then
          echo 用户 $NAME 会过期!
          echo 信息如下:
          chage -l $NAME
          echo ---
      else
          echo 用户 $NAME 不过期.
          echo ---
      fi
    fi
  done
done

exit 0