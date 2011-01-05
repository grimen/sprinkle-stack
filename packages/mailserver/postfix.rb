
package :postfix, :provides => :mailserver do
  description "Postfix - mail server"
  
  requires :postfix_core, :postfix_config, :postfix_autostart, :postfix_restart
  requires :postfix_ufw_rules # TODO: ufw
end

package :postfix_core do
  preseed_file = '/tmp/postfix.preseed'
  preseed_template = File.join(File.dirname(__FILE__), 'postfix', 'postfix.preseed')
  
  transfer preseed_template, preseed_file, :render => true
  
  apt 'postfix' do
    pre :install, "debconf-set-selections #{preseed_file}"
  end

  verify do
    has_executable 'postfix'
    has_file '/etc/init.d/postfix'
  end
end

package :postfix_ufw_rules do
  description "Postfix: ufw rules"
  requires :ufw, :curl, :postfix_core
  
  smtp_port = 25 unless defined?(smtp_port) || smtp_port.nil?
  
  ports = [smtp_port]
  
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

package :postfix_iptable_rules do
  description "Postfix: IP-tables rules"
  requires :iptables, :postfix_core, :curl
  
  iptables_file = '/etc/iptables.rules'
  iptables_rules_template = File.join(File.dirname(__FILE__), 'postfix', 'postfix.iptables.rules')
  
  push_text File.read(iptables_rules_template), iptables_file do
    # Reload IP-tables.
    post :install, "/sbin/iptables-restore < #{config_file} && /etc/init.d/ssh reload"
  end
  
  verify do
    file_contains iptables_file, `cat #{iptables_rules_template}`
  end
end

package :postfix_config do
  description "Postfix: Config"
  requires :postfix_core
  
  %w[main master].each do |config_name|
    config_file = "/etc/postfix/#{config_name}.conf"
    config_template = File.join(File.dirname(__FILE__), 'postfix', "#{config_name}.conf")

    transfer config_template, config_file, :render => true do
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
end

package :postfix_autostart do
  description "Postfix: Autostart on reboot"
  requires :postfix_core
  
  noop do
    pre :install, '/usr/sbin/update-rc.d postfix default'
  end
  
  verify do
  end
end

%w[start stop restart reload].each do |command|
  package :"postfix_#{command}" do
    requires :postfix_core

    noop do
      pre :install, "/etc/init.d/postfix #{command}"
    end
  end
end

