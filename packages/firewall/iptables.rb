
package :iptables, :provides => :firewall do
  description "Configure IP-tables (firewall)"
  
  requires :iptable_rules, :iptable_rules_autoload
end

package :iptable_rules do
  description "IP-tables: Default rules"
  
  config_file = '/etc/iptables.rules'
  config_template = File.read(File.join(File.dirname(__FILE__), 'iptables', 'iptables.rules'))

  transfer config_template, config_file, :render => true do
    # Reload IP-tables.
    post :install, "/sbin/iptables-restore < #{config_file}"
  end
  
  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :iptable_rules_autoload do
  description "IP-tables: Autoload IP-tables rules config on reboot"
  
  config_file = '/etc/network/if-pre-up.d/iptables'
  config_template = File.read(File.join(File.dirname(__FILE__), 'iptables', 'iptables.network.if-pre-up'))

  transfer config_template, config_file, :render => true do
    # Ensure the path exists.
    pre :install, "mkdir -p #{File.dirname(config_file)}"
    
    # Set proper permissions.
    post :install, "chmod +x /etc/network/if-pre-up.d/iptables"
  end
  
  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

%w[start stop restart reload].each do |command|
  package :"ssh_#{command}" do
    requires :ufw_core

    noop do
      pre :install, "/etc/init.d/ufw #{command}"
    end
  end
end
