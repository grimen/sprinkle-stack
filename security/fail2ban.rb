
package :fail2ban, :provides => :bruteforce_protection do
  description "Fail2ban - brute-force protection"
  
  requires :fail2ban_core, :fail2ban_config, :fail2ban_restart
end

package :fail2ban_core do
  apt 'fail2ban' do
    # post :install, "chown deployer:deployer -R /var/log/fail2ban"
  end
  
  verify do
    has_file '/etc/init.d/fail2ban'
  end
end

package :fail2ban_config do
  requires :fail2ban_core
  
  %w[fail2ban jail].each do |config_name|
    config_file = "/etc/fail2ban/#{config_name}.conf"
    config_template = File.join(File.dirname(__FILE__), 'fail2ban', "#{config_name}.conf")

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

package :fail2ban_restart do
  noop do
    pre :install, "/etc/init.d/fail2ban restart"
  end
end
