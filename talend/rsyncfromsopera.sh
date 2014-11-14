#!/bin/sh

if [ ! -f /var/samba/nightly/truelock ]; then
        touch /var/samba/nightly/truelock

	/usr/bin/rsync --exclude 'lock' -vzrtopg --progress rsync://rsync@91.250.81.83/talend /var/samba/nightly --password-file=/etc/server.pass

#       /usr/bin/rsync -vzrtopg taladmin@91.250.81.83:/ftproot/builds/ /var/samba/nightly --password-file=/etc/server.pass
	rm -f /var/samba/nightly/truelock
fi
