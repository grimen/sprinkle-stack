
package :mysql, :provides => :database do
  description 'MySQL Database'

  requires :mysql_core, :mysql_config, :mysql_roles, :mysql_root_password, :mysql_restart
  requires :mysql_ufw_rules # TODO: ufw
  optional :mysql_remote_access, :mysql_rubygem
end

# == References: "Preseed"
#   - http://www.rndguy.ca/2010/02/24/fully-automated-ubuntu-server-setups-using-preseed/

package :mysql_core do
  version '5.1'
  
  preseed_file = '/tmp/mysql.preseed'
  preseed_template = File.join(File.dirname(__FILE__), 'mysql', 'mysql.preseed')
  
  transfer preseed_template, preseed_file, :render => true
  
  apt 'mysql-server mysql-client libmysqlclient-dev' do
    pre :install, "debconf-set-selections #{preseed_file}"
    
    post :install, "chown -R #{deployer}:#{group} /var/log/mysql"
  end

  verify do
    has_executable 'mysql'
    has_executable 'mysqld'
    has_executable 'mysqladmin'
    
    has_file '/etc/init.d/mysql'
    
    has_file '/etc/logrotate.d/mysql'
  end
end

package :mysql_root_password do
  description "MySQL: Set database root password"
  requires :mysql_core
  
  db_password = nil unless defined?(db_password)
  
  print "Enter a new MySQL root password (default: #{db_password}): "
  db_password = gets || ''

  runner %{mysqladmin -u root password #{db_password}}
  
  verify do
    # TODO: Test if password was set correctly.
  end
end

package :mysql_ufw_rules do
  description "MySQL: ufw rules"
  requires :ufw, :curl, :mysql_core
  
  db_port = 3306 unless defined?(db_port) || db_port.nil?
  
  print "Enter a new MySQL root password (default: #{db_port if defined?(db_port)}): "
  db_port = gets || ''
  
  ports = [db_port]
  
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

package :mysql_iptable_rules do
  description "MySQL: IP-tables rules"
  requires :mysql_core
  
  db_port = 3306 unless defined?(db_port) || db_port.nil?
  
  puts "Enter a new MySQL root password (default: #{db_port if defined?(db_port)}): "
  db_port = gets || ''
  
  iptables_rules_file = '/etc/iptables.rules'
  iptables_rules_template = File.join(File.dirname(__FILE__), 'mysql', 'mysql.iptables.rules')
  
  push_text File.read(iptables_rules_template), iptables_rules_file, :render => true do
    # Reload IP-tables.
    post :install, "/sbin/iptables-restore < #{config_file}"
  end
  
  verify do
    file_contains iptables_rules_file, `cat #{iptables_rules_template}`
  end
end

package :mysql_grants do
  description "MySQL: Default access roles/rights (grants)"
  requires :mysql_core
  
  grants_file = '/tmp/mysql.grants.sql'
  grants_template = File.join(File.dirname(__FILE__), 'mysql', 'mysql.grants.sql')
  
  runner %{mysql -u root < #{grants_file}}
  
  verify do
    # TODO: Check that grants got set.
  end
end

package :mysql_config do
  description "MySQL: Config"
  requires :mysql_core
  
  %w(my.conf).each do |config_file|
    config_file = "/etc/mysql/#{config_file}"
    config_template = File.join(File.dirname(__FILE__), 'mysql', "#{config_file}")
    
    transfer config_template, config_file, :render => true do
      pre :install, "mkdir -p #{File.dirname(config_file)} && test -f #{config_file} && rm #{config_file}"
    end
    
    verify do
      has_file config_file
      file_contains config_file, `head -n 1 #{config_template}`
    end
  end
end

package :mysql_remote_access do
  requires :mysql_core
  
  # TODO
  
  verify do
  end
end

package :mysql_rubygem do
  description 'MySQL: Ruby driver gem'
  requires :ruby, :mysql_core
  
  gem 'mysql2'

  verify do
    has_gem 'mysql2'
    ruby_can_load 'mysql2'
  end
end

package :mysql_autostart do
  description "MySQL: Autostart on reboot"
  requires :mysql_core
  
  runner '/usr/sbin/update-rc.d mysql default'
end

%w[start stop restart reload].each do |command|
  package :"mysql_#{command}" do
    requires :mysql_core

    runner "/etc/init.d/mysql #{command}"
  end
end

