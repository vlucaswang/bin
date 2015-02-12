install_set_ulimit()
{
  cat >/etc/security/limits.d/99-grid-oracle-limits.conf << EOF
  * soft nofile 1024
  * hard nofile 65536
  * - nproc 16384
  * soft stack 10240
  * hard stack 32768
  oracle hard memlock 1048576
  oracle soft memlock 1048576
  EOF
  sed -i 's/1024/10240/' /etc/security/limits.d/90-nproc.conf
}