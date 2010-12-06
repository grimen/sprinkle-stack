# sprinkled: memcached.logrotate.d v1
/var/log/memcached/*.log {
  rotate 30
  daily
  missingok
  notifempty
  compress
  delaycompress
  copytruncate
}