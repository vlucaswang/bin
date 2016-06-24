if [ ! -f /var/samba/nightly/lock ]; then
	touch /var/samba/nightly/lock

	lftp -f /root/scripts/folder_to_download_temp.txt

	rm -f /var/samba/nightly/lock
fi
