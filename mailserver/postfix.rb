
package :postfix, :provides => :mailserver do
  description "Postfix - mail server"
  
  requires :postfix_core, :postfix_config, :postfix_autostart, :postfix_restart
end

package :postfix_core do
  preseed_file = '/tmp/postfix.preseed'
  preseed_template = File.join(File.dirname(__FILE__), 'postfix', 'postfix.preseed')
  
  transfer preseed_template, preseed_file
  
  verify do
    has_file preseed_file
    file_contains preseed_file, `head -n 1 #{preseed_file}`
  end
  
  apt 'postfix' do
    pre :install, "debconf-set-selections #{preseed_file}"
  end

  verify do
    has_executable 'postfix'
    has_file '/etc/init.d/postfix'
  end
end

package :postfix_iptable_rules do
  requires :iptables, :postfix_core
  
  iptables_file = '/etc/iptables.rules'
  iptables_rules_template = File.join(File.dirname(__FILE__), 'postfix', 'postfix.iptables.rules')
  
  push_text File.read(iptables_rules_template), iptables_file do
    # Reload IP-tables.
    post :install, "/sbin/iptables-restore < #{config_file} && /etc/init.d/ssh reload"
  end
  
  verify do
    file_contains iptables_file
  end
end

package :postfix_config do
  requires :postfix_core
  
  %w[main master].each do |config_name|
    config_file = "/etc/postfix/#{config_name}.conf"
    config_template = File.join(File.dirname(__FILE__), 'postfix', "#{config_name}.conf")

    transfer config_template, config_file, :render => false do
      pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
      post :install, "chmod 0644 #{config_file}"
    end
    
    verify do
      has_file config_file
      file_contains config_file, `head -n 1 #{config_template}`
    end
  end
end

package :postfix_autostart do
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

