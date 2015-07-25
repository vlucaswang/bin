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
	read -p "请输入IP" IP

#	ssh-copy-id root@$IP
	scp ~/.ssh/id_rsa.pub root@$IP:/root/.ssh/authorized_keys
	scp Linux_check.sh root@$IP:/tmp/
	ssh root@$IP 'chmod +x /tmp/Linux_check.sh;bash /tmp/Linux_check.sh'
	scp -r root@$IP:/tmp/sysssc/* .
	ssh root@$IP "sed -i '\$d' .ssh/authorized_keys;rm -rf /tmp/sysssc;rm -f /tmp/Linux_check.sh"
done

exit 0