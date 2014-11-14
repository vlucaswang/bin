#!/bin/sh
cd /var/samba/nightly/
find . -maxdepth 1 -name "*NB.*" -type f -mtime +30 -exec rm -rf {} \;
