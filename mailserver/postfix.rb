
package :postfix, :provides => :mailserver do
  description "Postfix - mail server"
  
  requires :postfix_core, :postfix_config, :postfix_autostart, :postfix_restart
end

package :postfix_core do
  apt 'postfix' do
    # post :install, "chown deployer:deployer -R /var/log/mail.log"
    # post :install, "chown deployer:deployer -R /var/log/mail.info"
    # post :install, "chown deployer:deployer -R /var/log/mail.warn"
    # post :install, "chown deployer:deployer -R /var/log/mail.err"
  end

  verify do
    has_executable 'postfix'
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

package :postfix_reload do
  requires :postfix_core
  
  noop do
    pre :install, '/etc/init.d/postfix reload'
  end
end

package :postfix_restart do
  requires :postfix_core
  
  noop do
    pre :install, '/etc/init.d/postfix restart'
  end
end
