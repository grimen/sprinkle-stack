# sprinkled: nginx.logrotate.d v1

# Basic
# /var/log/nginx/*.log {
#   rotate 30
#   daily
#   missingok
#   notifempty
#   compress
#   delaycompress
#   copytruncate
}

# Custom
/var/log/nginx/*.log {
  # Rotate the logfile(s) daily
  daily
  # Adds extension like YYYYMMDD instead of simply adding a number
  dateext
  # If log file is missing, go on to next one without issuing an error msg
  missingok
  # Save logfiles for the last 49 days
  rotate 30
  # Old versions of log files are compressed with gzip
  compress
  # Postpone compression of the previous log file to the next rotation cycle
  delaycompress
  # Do not rotate the log if it is empty
  notifempty
  # Create mode owner group
  create 644 deployer deployer
  # After logfile is rotated and nginx.pid exists, send the USR1 signal
  postrotate
     [ ! -f /usr/local/nginx/logs/nginx.pid ] || kill -USR1 `cat
     /usr/local/nginx/logs/nginx.pid`
  endscript
}
