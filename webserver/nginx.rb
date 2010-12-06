
package :nginx, :provides => :webserver do
  description "Nginx"

  requires :nginx_passenger, :nginx_config, :nginx_logrotate, :nginx_default_vhost, :nginx_autostart, :nginx_restart
end

package :nginx_passenger do
  description "Passenger Nginx"

  requires :passenger

  noop do
    post :install, "passenger-install-nginx-module --auto --auto-download --prefix=/usr/local/nginx --sbin-path=/usr/local/sbin"
    post :install, "mkdir -p /var/log/nginx && chown deployer:deployer -R /var/log/nginx"
  end

  daemon_file = '/etc/init.d/nginx'
  daemon_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.init.d')

  transfer daemon_template_file, daemon_file, :render => false do
    post :install, "chmod +x /etc/init.d/nginx"
  end

  verify do
    has_executable '/usr/local/sbin/nginx'
    has_file '/etc/init.d/nginx'
    has_process 'nginx'
  end
end

package :nginx_autostart do
  requires :nginx_core
  
  noop do
    pre :install, "/usr/sbin/update-rc.d -f nginx defaults"
  end
  
  verify do
  end
end

package :nginx_iptable_rules do
  requires :nginx_core
  
  # TODO
  
  verify do
  end
end

package :nginx_config do
  requires :nginx_passenger

  config_file = '/usr/local/nginx/conf/nginx.conf'
  config_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.conf')

  transfer config_template_file, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :nginx_default_vhost do
  requires :nginx_passenger

  config_file = '/usr/local/nginx/conf/vhosts/vhost.sample.conf'
  config_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.vhost.conf')

  transfer config_template_file, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :nginx_logrotate do
  requires :nginx_passenger, :logrotate
  
  config_file = '/etc/logrotate.d/nginx'
  config_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.logrotate.d')

  transfer config_template_file, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
    post :install, "chmod 0644 #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :nginx_restart do
  requires :nginx_passenger
  
  noop do
    pre :install, "/etc/init.d/nginx restart"
  end
end
