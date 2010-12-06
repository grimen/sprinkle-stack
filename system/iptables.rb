
package :iptables, :provides => :firewall do
  description "Configure iptables (firewall)"
  
  requires :iptable_rules, :iptable_rules_autoload
end

package :iptable_rules do
  config_file = '/etc/iptables.rules'
  config_template = File.read(File.join(File.dirname(__FILE__), 'iptables', 'app.logrotate.conf'))

  transfer config_template, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
    post :install, "/sbin/iptables-restore < /etc/iptables.up.rules"
    post :install, "/etc/init.d/ssh reload"
  end
  
  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :iptable_rules_autoload do
  config_file = '/etc/network/if-pre-up.d/iptables'
  config_template = File.read(File.join(File.dirname(__FILE__), 'iptables', 'iptables.network.if-pre-up'))

  transfer config_template, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
    post :install, "chmod +x /etc/network/if-pre-up.d/iptables"
    post :install, "/etc/init.d/ssh reload"
  end
  
  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end
