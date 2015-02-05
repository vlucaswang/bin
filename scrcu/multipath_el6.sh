#!/bin/bash
yum -y install device-mapper-multipath
cp /etc/multipath.conf /etc/multipath_original.conf
mpathconf --enable --with_multipathd y --with_module y

cat <<EOF >/etc/multipath.conf
defaults {
	find_multipaths yes
	user_friendly_names yes
	polling_interval 5
	no_path_retry 0
	failback manual
}
EOF

chkconfig multipathd on
service multipathd start
