/etc/sysconfig/sbd

scp /etc/corosync/{corosync.conf,authkey} node2:/etc/corosync/
scp /etc/csync2/{csync2.cfg,key_hagroup} node2:/etc/corosync/
vim /etc/corosync/corosync.conf
rcopenais start
insserv openais
/etc/init.d/csync2 start
chkconfig csync2 on
crm_mon -i1
echo novell | passwd --stdin hacluster