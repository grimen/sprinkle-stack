
package :mysql, :provides => :database do
  description 'MySQL Database'

  requires :mysql_core, :mysql_config, :mysql_iptable, :mysql_roles, :mysql_root_password, :mysql_restart
  optional :mysql_remote_access, :mysql_rubygem
end

package :mysql_core do
  version '5.1'
  
  apt 'mysql-server mysql-client libmysqlclient-dev' do
    # post :install, "chown deployer:deployer -R /var/log/mysql"
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
  requires :mysql_core
  
  db_password = nil unless defined?(db_password)
  
  puts "Enter a new MySQL root password (default: #{db_password}): "
  db_password = gets || ''

  noop do
    pre :install, %{mysqladmin -u root password #{db_password}}
  end
  
  verify do
    # TODO: Test if password was set correctly.
  end
end

package :mysql_iptable_rules do
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
  requires :mysql_core
  
  grants_file = '/tmp/mysql.grants.sql'
  grants_template = File.join(File.dirname(__FILE__), 'mysql', 'mysql.grants.sql')
  
  noop do
    pre :install, %{mysql -u root < #{grants_file}}
  end
  
  verify do
    # TODO: Check that grants got set.
  end
end

package :mysql_config do
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
  description 'MySQL Ruby gem'
  requires :ruby, :mysql_core
  
  gem 'mysql2'

  verify do
    has_gem 'mysql2'
    ruby_can_load 'mysql2'
  end
end

package :mysql_autostart do
  requires :mysql_core
  
  noop do
    pre :install, '/usr/sbin/update-rc.d mysql default'
  end
  
  verify do
  end
end

%w[start stop restart reload].each do |command|
  package :"mysql_#{command}" do
    requires :mysql_core

    noop do
      pre :install, "/etc/init.d/mysql #{command}" # TODO: postgresql or postgresql-common?
    end
  end
end

