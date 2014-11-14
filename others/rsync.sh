#!/bin/sh
SOURUSR=
SOURURL=
SOURMODULE=
DESTDIR=

if [ ! -f $DESTDIR/lock ]; then
	touch $DESTDIR/lock

	/usr/bin/rsync -vzrtopg --progress rsync://$SOURUSR@$SOURURL/$SOURMODULE $DESTDIR --password-file=/etc/server.pass

	rm -f $DESTDIR/lock
fi

exit 0
