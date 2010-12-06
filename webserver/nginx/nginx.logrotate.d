# sprinkled: memcached.logrotate.d v1
/var/log/nginx/*.log {
  rotate 30
  daily
  missingok
  notifempty
  compress
  delaycompress
  copytruncate
}