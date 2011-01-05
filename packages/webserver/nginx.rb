
package :nginx, :provides => :webserver do
  description "Nginx"
  
  requires :nginx_core, :nginx_config, :nginx_logrotate, :nginx_default_vhost, :nginx_autostart, :nginx_restart
end

package :nginx_passenger, :provides => :nginx_core do
  description "Passenger Nginx"

  requires :passenger, :nginx_dependencies

  nginx_sbin_path = '/usr/local/sbin'
  nginx_flags = "--sbin-path=#{nginx_sbin_path}"
  nginx_prefix = File.join(@options[:prefix], 'nginx')
  passenger_nginx_flags = %{--auto --auto-download --prefix=#{@options[:prefix]}/nginx --extra-configure-flags="#{nginx_flags}"}
  
  noop do
    post :install, "rvmsudo passenger-install-nginx-module #{passenger_nginx_flags}"
    post :install, 'mkdir -p /var/log/nginx'
    post :install, "chown -R #{deployer}:#{group} /var/log/nginx"
  end

  daemon_file = '/etc/init.d/nginx'
  daemon_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.init.d')

  transfer daemon_template_file, daemon_file, :render => true do
    post :install, 'chmod +x /etc/init.d/nginx'
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

package :nginx_ufw_rules do
  description "Nginx: ufw rules"
  requires :ufw, :curl, :nginx_core
  
  http_port = 80
  https_port = 443
  
  ports = [http_port, https_port]
  
  noop do
    [*ports].each do |port|
      pre :install, "ufw allow to 0.0.0.0/0 port #{port}"
      
      post :install, "curl localhost:#{port} > /tmp/ufw.port.#{port}.test"
    end
  end
  
  verify do
    [*ports].each do |port|
      file_contains_not "/tmp/ufw.port.#{port}.test", "couldn't connect to host"
    end
  end
end

package :nginx_iptable_rules do
  description "Nginx: IP-table rules"
  requires :nginx_core
  
  iptables_file = '/etc/iptables.rules'
  iptables_template = File.join(File.dirname(__FILE__), 'nginx', 'nginx.iptables.rules')
  
  push_text File.read(iptables_template), iptables_file, :render => true do
    # Reload IP-tables.
    post :install, "/sbin/iptables-restore < #{iptables_file}"
  end
  
  verify do
    has_file iptables_file
    file_contains iptables_file, `cat #{iptables_template}`
  end
end

package :nginx_config do
  description "Nginx: Config"
  requires :nginx_core

  config_file = File.join(@options[:prefix], '/nginx/conf/nginx.conf')
  config_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.conf')

  transfer config_template_file, config_file, :render => true do
    # Ensure path exists.
    pre :install, "mkdir -p #{File.dirname(config_file)}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :nginx_default_vhost do
  description "Nginx: Default vhost"
  requires :nginx_core

  config_file = '/usr/local/nginx/conf/vhosts/vhost.sample.conf'
  config_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.vhost.conf')

  transfer config_template_file, config_file, :render => true do
    # Ensure path exists.
    pre :install, "mkdir -p #{File.dirname(config_file)}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :nginx_logrotate do
  description "Nginx: Log rotation"
  requires :nginx_core, :logrotate
  
  config_file = '/etc/logrotate.d/nginx'
  config_template_file = File.join(File.dirname(__FILE__), 'nginx', 'nginx.logrotate.d')

  transfer config_template_file, config_file, :render => true do
    # Ensure path exists.
    pre :install, "mkdir -p #{File.dirname(config_file)}"
    
    # Set proper permissions.
    post :install, "chmod 0644 #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :nginx_autostart do
  description "Nginx: Autostart on reboot"
  requires :nginx_core
  
  runner '/usr/sbin/update-rc.d nginx default'
end

%w[start stop restart reload].each do |command|
  package :"nginx_#{command}" do
    requires :nginx_core

    runner "/etc/init.d/nginx #{command}"
  end
end

