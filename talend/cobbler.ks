# kickstart template for Fedora 8 and later.
# (includes %end blocks)
# do not use with earlier distros

#platform=x86, AMD64, or Intel EM64T
# System authorization information
auth  --useshadow  --enablemd5
# System bootloader configuration
bootloader --location=mbr  --driveorder=/dev/sda
# Partition clearing information
clearpart --all --initlabel
# Use text mode install
text
# Firewall configuration
firewall --disabled
# Run the Setup Agent on first boot
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# Use network installation
url --url=http://192.168.30.17/cblr/links/CentOS-6.4-bin-DVD1-x86_64
# If any cobbler repo definitions were referenced in the kickstart profile, include them here.

# Network information
network --bootproto=dhcp --device=eth0 --onboot=on  

# Reboot after installation
reboot

#Root password
rootpw --iscrypted $1$p4BbJlfk$E4KlU9yPxPGxDR2IT9.0t/
# SELinux configuration
selinux --disabled
# Do not configure the X Window System
skipx
# System timezone
timezone  Asia/Shanghai
# Install OS instead of upgrade
install
# Clear the Master Boot Record
zerombr yes
# Allow anaconda to partition the system as needed
part /boot --ondisk=/dev/sda --fstype="ext4" --size=200 
part pv.01 --grow --size=1
volgroup myvg pv.01
logvol swap --vgname=myvg --size=8192 --fstyp="swap" --name=lv_swap
logvol / --vgname=myvg --size=30720 --fstyp="ext4" --name=lv_root
logvol /var --vgname=myvg --size=1 --grow --fstyp="ext4" --name=lv_var

%pre
set -x -v
exec 1>/tmp/ks-pre.log 2>&1

# Once root's homedir is there, copy over the log.
while : ; do
    sleep 10
    if [ -d /mnt/sysimage/root ]; then
        cp /tmp/ks-pre.log /mnt/sysimage/root/
        logger "Copied %pre section log to system"
        break
    fi
done &


wget "http://192.168.30.17/cblr/svc/op/trig/mode/pre/profile/CentOS-6.4-bin-DVD1-x86_64_nogui" -O /dev/null

# Enable installation monitoring

/usr/sbin/parted --script /dev/sda mklabel gpt
/usr/sbin/parted --script /dev/sdb mklabel gpt
/usr/sbin/parted --script /dev/sdc mklabel gpt
%end

%packages
@ Base
%end

%post
set -x -v
exec 1>/root/ks-post.log 2>&1

# Start yum configuration
wget "http://192.168.30.17/cblr/svc/op/yum/profile/CentOS-6.4-bin-DVD1-x86_64_nogui" --output-document=/etc/yum.repos.d/cobbler-config.repo

# End yum configuration



# Start post_install_network_config generated code
# End post_install_network_config generated code




# Start download cobbler managed config files (if applicable)
# End download cobbler managed config files (if applicable)

# Start koan environment setup
echo "export COBBLER_SERVER=192.168.30.17" > /etc/profile.d/cobbler.sh
echo "setenv COBBLER_SERVER 192.168.30.17" > /etc/profile.d/cobbler.csh
# End koan environment setup

# begin Red Hat management server registration
# not configured to register to any Red Hat management server (ok)
# end Red Hat management server registration

# Begin cobbler registration
if [ -f "/usr/bin/cobbler-register" ]; then
    cobbler-register --server=192.168.30.17 --fqdn '*AUTO*' --profile=CentOS-6.4-bin-DVD1-x86_64_nogui --batch
fi
# End cobbler registration

# Enable post-install boot notification

# Start final steps

wget "http://192.168.30.17/cblr/svc/op/ks/profile/CentOS-6.4-bin-DVD1-x86_64_nogui" -O /root/cobbler.ks
wget "http://192.168.30.17/cblr/svc/op/trig/mode/post/profile/CentOS-6.4-bin-DVD1-x86_64_nogui" -O /dev/null
# End final steps
sed -i 's/id:3:initdefault:/id:5:initdefault:/g' /etc/inittab
%end