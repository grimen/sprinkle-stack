# sprinkled: app.logrotate.d v1

# == Example:

# /home/deployer/apps/example.com/shared/log/*.log {
#   daily
#   missingok
#   rotate 30
#   compress
#   delaycompress
#   sharedscripts
#   create 644 deployer deployer
#   postrotate
#     touch /home/deployer/apps/example.com/current/tmp/restart.txt
#   endscript
# }

# == Reference:
#
# daily - Do this every day
#   On userscripts.org, my logs are rotated every morning at 6:25am. To find out when your system will run, cat /etc/crontab.
#
# missingok - Don't worry if there are no logs
#   Your logrotate software is not how you want to learn that your site is down.
#
# rotate 30 - Keep 30 days worth of these around
#   Rails logs compress well. 30 days compressed is less than a couple of days of uncompressed logs. If something goes wrong you can parse the logs.
#
# compress - Compress the rotated logs
#   gzip the log files so they only take up a fraction of the space
#
# delaycompress - Compress yesterday's rotation, not the current rotation
#   Logrotate will move production.log to production.log.1, but since passenger is still running it will still be writing to the file. Rather than than forcing all requests to be terminated so the file can be compressed, we'll just do it tomorrow. By then all your passenger processes will have been restarted so they will be writing to the new production.log.
#
# postrotate/endscript - run some code after rotation which tells passenger to restart
#   After we are done moving production.log to production.log.1 we need to restart our application servers. Over the course of several minutes passenger will kill old app servers and start new ones. The old ones won't get any new requests so production.log.1 will stop growing after existing requests are finished.
#
# sharedscripts - only run postrotate once, not once per log file in shared/log
#   You don't want to touch tmp/restart.txt for each log file (newrelic_agent.passenger.log, searchd.log, backgroundjob, and so on).
#