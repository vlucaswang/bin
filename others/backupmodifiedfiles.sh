#!/bin/sh

BACKUPFILE=back-$(date +%m-%d-%Y)
archive=${1:-$BACKUPFILE}

find . -mtime -l -type f -print0 | xargs -0 tar rvf "$archive.tar"
#slower but better portable solution below
#find . -mtime -l -type f -exec tar rvf "$archive.tar" '{}' \;
gzip $archive.tar
echo "Directory $PWD backed up in archive file \"$archive.tar.gz\"."

exit 0
