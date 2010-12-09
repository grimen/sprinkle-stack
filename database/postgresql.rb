
package :postgresql, :provides => :database do
  description 'PostgreSQL database'
  
  requires :postgresql_core, :postgresql_config, :postgresql_grants, :postgresql_iptable, :postgresql_root_password, :postgresql_restart
  optional :postgresql_remote_access, :postgresql_rubygem
end

package :postgresql_core do
  version '8.4'
  
  apt 'postgresql postgresql-client libpq-dev' do
    # post :install, "chown deployer:deployer -R /var/log/postgresql"
    post :install, 'ln -s /etc/init.d/postgresql-8.4 /etc/init.d/postgresql'
  end
  
  verify do
    has_executable 'psql'
    
    has_file '/etc/init.d/postgresql-8.4'
    has_file '/etc/logrotate.d/postgresql-common'
    
    has_symlink '/etc/init.d/postgresql', '/etc/init.d/postgresql-8.4'
  end
end

package :postgresql_root_password do
  requires :postgresql_core
  
  db_password = nil unless defined?(db_password)
  
  puts "Enter a new PostgreSQL root password (default: #{db_password}): "
  db_password = gets || ''
  
  noop do
    pre :install,
      %{psql -U postgres template1 -c "ALTER USER #{deployer} with encrypted password '#{db_password}';"}
  end
  
  verify do
    # TODO: Test if password was set correctly.
  end
end

package :postgresql_iptable_rules do
  requires :postgresql_core, :ssh
  
  db_port = 5432 unless defined?(db_port) || db_port.nil?
  
  puts "Enter a new PostgreSQL root password (default: #{db_port if defined?(db_port)}): "
  db_port = gets || ''
  
  iptables_rules_file = '/etc/iptables.rules'
  iptables_rules_template = File.join(File.dirname(__FILE__), 'postgresql', 'postgresql.iptables.rules')
  
  push_text File.read(iptables_rules_template), iptables_rules_file, :render => true do
    # Reload IP-tables.
    post :install, "/sbin/iptables-restore < #{config_file}"
  end
  
  verify do
    file_contains iptables_rules_file, `cat #{iptables_rules_template}`
  end
end

# psql-reference: http://www.psn.co.jp/PostgreSQL/pgbash/examples/diffpsql.html
package :postgresql_grants do
  requires :postgresql_core
  
  grants_file = '/tmp/postgresql.grants.sql'
  grants_template = File.join(File.dirname(__FILE__), 'mysql', 'mysql.grants.sql')
  
  transfer grants_template, grants_file, :render => true do
    pre :install, %{psql -U postgres template1 -f #{grants_file}}
  end
  
  verify do
    # TODO: Check that grants got set.
  end
end

package :postgresql_config do
  requires :postgresql_core
  
  %w(postgresql.conf pg_hba.conf).each do |config_file|
    config_file = "/etc/postgresql/8.4/main/#{config_file}"
    config_template = File.join(File.dirname(__FILE__), 'postgresql', "#{config_file}")
    
    transfer config_template, config_file, :render => false do
      pre :install, "mkdir -p #{File.dirname(config_file)} && test -f #{config_file} && rm #{config_file}"
    end
    
    verify do
      has_file config_file
      file_contains config_file, `head -n 1 #{config_template}`
    end
  end
end

package :postgresql_remote_access do
  requires :postgresql_core
  
  # TODO
  
  verify do
  end
end

package :postgresql_rubygem do
  description 'PostgreSQL Ruby gem'
  
  requires :ruby, :postgresql_core
  
  gem 'pg'

  verify do
    has_gem 'pg'
    ruby_can_load 'pg'
  end
end

package :postgresql_autostart do
  requires :postgresql_core
  
  noop do
    pre :install, '/usr/sbin/update-rc.d postgresql default'
  end
  
  verify do
  end
end

%w[start stop restart reload].each do |command|
  package :"postgresql_#{command}" do
    requires :postgresql_core

    noop do
      pre :install, "/etc/init.d/postgresql #{command}"
    end
  end
end
