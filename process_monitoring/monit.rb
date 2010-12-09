
package :monit, :provides => :process_monitoring do
  description "Monit - process monitoring"
  
  requires :monit_core, :monit_config, :monit_restart
end

package :monit_core do
  apt 'monit'

  verify do
    has_executable 'monit'
    
    has_file '/etc/init.d/monit'
    has_file '/etc/logrotate.d/monit'
  end
end

package :monit_config do
  requires :monit_core
  
  config_file = '/etc/monitrc'
  config_template = File.join(File.dirname(__FILE__), 'monit', 'monitrc')
  
  transfer config_template, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
    
    # Allow monit startup.
    post :install, "echo > /etc/default/monit 'startup=1'"
  end
  
  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :monit_autostart do
  requires :monit_core
  
  noop do
    pre :install, '/usr/sbin/update-rc.d monit default'
  end
  
  verify do
  end
end

%w[start stop restart reload].each do |command|
  package :"monit_#{command}" do
    requires :monit_core

    noop do
      pre :install, "/etc/init.d/monit #{command}"
    end
  end
end

# package :monit_ssh do
#   config_file = '/etc/monitrc'
#   config_text = %q[
# # sprinkled: monit-ssh v1
# check process sshd with pidfile /var/run/sshd.pid
# start program "/etc/init.d/ssh start"
# stop program "/etc/init.d/ssh stop"
# if failed port 2244 protocol ssh then restart
# ].lstrip
# 
#   push_text config_text, config_file
# 
#   verify do
#     file_contains config_file, "monit-ssh"
#   end
# end
# 
# package :monit_memcached do
#   config_file = '/etc/monitrc'
#   config_text = %q[
# # monit-memcached
# check process memcached with pidfile /var/run/memcached.pid
# if failed host 127.0.0.1 port 11211 for 2 cycles then restart
# if totalmemory is greater than 20% for 2 cycles then alert
# ].lstrip
# 
#   push_text config_text, config_file
# 
#   verify do
#     file_contains config_file, "monit-memcached"
#   end
# end
# 
# package :monit_nginx do
#   config_file = '/etc/monitrc'
#   config_text = %q[
# # monit-nginx
# check process nginx with pidfile /var/run/nginx.pid
# start program = "/etc/init.d/nginx start"
# stop  program = "/etc/init.d/nginx stop"
# if failed host 127.0.0.1 port 80 for 2 cycles then restart
# if totalmemory is greater than 60% for 2 cycles then alert
# ].lstrip
# 
#   push_text config_text, config_file
# 
#   verify do
#     file_contains config_file, "monit-nginx"
#   end
# end
# 
# package :monit_nginx_with_varnish do
#   config_file = '/etc/monitrc'
#   config_text = %q[
# # monit-nginx-varnish
# check process nginx with pidfile /var/run/nginx.pid
# start program = "/etc/init.d/nginx start"
# stop  program = "/etc/init.d/nginx stop"
# if failed host 127.0.0.1 port 8080 for 2 cycles then restart
# if totalmemory is greater than 60% for 2 cycles then alert
# ].lstrip
# 
#   push_text config_text, config_file
# 
#   verify do
#     file_contains config_file, "monit-nginx-varnish"
#   end
# end
# 
# package :monit_varnish do
#   config_file = '/etc/monitrc'
#   config_text = %q[
# # monit-varnish
# check process varnish with pidfile /var/run/varnishd.pid
# start program = "/etc/init.d/varnish start"
# stop  program = "/etc/init.d/varnish stop"
# if failed host 127.0.0.1 port 80 for 2 cycles then restart
# if totalmemory is greater than 60% for 2 cycles then alert
# ].lstrip
# 
#   push_text config_text, config_file
# 
#   verify do
#     file_contains config_file, "monit-varnish"
#   end
# end
