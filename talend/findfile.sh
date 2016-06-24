#!/bin/sh
find /var/samba/public -atime +100 -exec ls -l {} \; |awk 'BEGIN{count=0;size=0;} \
 {count = count + 1; size = size + $5/1024/1024;} \
 END{print "Total count " count; \
   print "Total Size " size/1024 " GB" ; \
   print "Avg Size " size / count "MB"; \
   print "—"}'
