
package :fail2ban, :provides => :bruteforce_protection do
  description "Fail2ban - brute-force protection"
  
  requires :fail2ban_core, :fail2ban_config, :fail2ban_restart
end

package :fail2ban_core do
  apt 'fail2ban' do
    post :install, "chown -R #{deployer}:#{group} /var/log/fail2ban"
  end
  
  verify do
    has_file '/etc/init.d/fail2ban'
  end
end

package :fail2ban_config do
  description "Fail2ban: Config"
  requires :fail2ban_core
  
  %w[fail2ban jail].each do |config_name|
    config_file = "/etc/fail2ban/#{config_name}.conf"
    config_template = File.join(File.dirname(__FILE__), 'fail2ban', "#{config_name}.conf")

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

package :fail2ban_autostart do
  description "Fail2ban: Autostart on reboot"
  requires :fail2ban_core
  
  runner '/usr/sbin/update-rc.d fail2ban default'
end

%w[start stop restart reload].each do |command|
  package :"fail2ban_#{command}" do
    requires :fail2ban_core

    runner "/etc/init.d/fail2ban #{command}"
  end
end
