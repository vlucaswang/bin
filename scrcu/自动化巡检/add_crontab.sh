#!/bin/sh

#command="sh /root/autocheck.sh"
#job="0 6 * * * $command"
#file="/root/ansible/tmphost3"

for line in `cat /root/ansible/tmphost6 |grep -v ^# |awk '{print $1}'`
#for line in "10.128.128.103"
do
  scp /root/ansible/autocheck.sh root@$line:/root/autocheck.sh
  ssh root@$line 'bash /root/autocheck.sh'
#  ssh root@$line 'crontab -l | { cat; echo $job; } | crontab -'
#  ssh root@$line 'cat <(fgrep -i -v "autocheck.sh" <(crontab -l)) <(echo "40 6 * * * /root/autocheck.sh") | crontab -'
#  ssh root@$line 'crontab -l | grep -v "$command" > "$tmpfile" ; echo "$job" >> "$tmpfile" ; crontab "$tmpfile" ; rm -f "$tmpfile"'
done

exit 0
