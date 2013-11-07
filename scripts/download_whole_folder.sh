#!bin/bash
echo "script start at 'date +%Y-%m-%d %H:%M:%S'"
HOST="build.talend.com"
USER="build-admin"
PASS="remy_build"
LCD="/var/samba/nightly"
RCD=""
/usr/sbin/lftp << EOF

