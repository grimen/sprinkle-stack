
package :nginx, :provides => :webserver do
  description "Nginx"

  requires :nginx_passenger, :nginx_config, :nginx_logrotate, :nginx_default_vhost, :nginx_autostart, :nginx_restart
end

package :nginx_passenger do
  description "Passenger Nginx"

  requires :passenger, :nginx_dependencies

  nginx_sbin_path = '/usr/local/sbin'
  nginx_flags = "--sbin-path=#{nginx_sbin_path}"
  nginx_prefix = File.join(@options[:prefix], 'nginx')
  passenger_nginx_flags = %{--auto --auto-download --prefix=#{@options[:prefix]}/nginx --extra-configure-flags="#{nginx_flags}"}
  
  noop do
    post :install, "rvmsudo passenger-install-nginx-module #{passenger_nginx_flags}"
    post :install, "mkdir -p /var/log/nginx && chown deployer:deployer -R /var/log/nginx"
  end

  daemon_file = '/etc/init.d/nginx'
  daemon_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.init.d')

  transfer daemon_template_file, daemon_file, :render => false do
    post :install, "chmod +x /etc/init.d/nginx"
  end

  verify do
    has_executable nginx_sbin_path
    has_file '/etc/init.d/nginx'
    has_process 'nginx'
  end
end

package :nginx_dependencies do
  apt 'libcurl4-openssl-dev'
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
  
  config_file = '/etc/iptables.rules'
  config_template = File.join(File.dirname(__FILE__), 'nginx', 'nginx.iptables.rules')
  
  # TODO: Append iptables.rules
  
  verify do
    file_contains config_file, `cat #{config_template}`
  end
end

package :nginx_config do
  requires :nginx_passenger

  config_file = File.join(@options[:prefix], '/nginx/conf/nginx.conf')
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

package :nginx_autostart do
  requires :passenger_nginx
  
  noop do
    pre :install, '/usr/sbin/update-rc.d nginx default'
  end
  
  verify do
  end
end

%w[start stop restart reload].each do |command|
  package :"nginx_#{command}" do
    requires :nginx_passenger

    noop do
      pre :install, "/etc/init.d/nginx #{command}"
    end
  end
end

