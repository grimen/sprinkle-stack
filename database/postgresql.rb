
package :postgresql, :provides => :database do
  description 'PostgreSQL database'
  
  requires :postgresql_core, :postgresql_config, :postgresql_iptable, :postgresql_roles, :postgresql_root_password, :postgresql_restart
  optional :postgresql_remote_access, :postgresql_rubygem
end

package :postgresql_core do
  # version '8.4'
  
  apt 'postgresql postgresql-client libpq-dev' do
    # post :install, "chown deployer:deployer -R /var/log/postgresql"
  end
  
  verify do
    has_executable 'psql'
    has_file '/etc/logrotate.d/postgresql-common'
  end
end

package :postgresql_root_password do
  requires :postgresql_core
  
  # TODO
  
  verify do
  end
end

package :postgresql_iptable_rules do
  requires :postgresql_core, :ssh
  
  config_file = '/etc/monitrc'
  # TODO
  
  verify do
  end
end

#   config_file = '/etc/monitrc'
#   config_text = %q[
# # sprinkled: monit-ssh v1
# check process sshd with pidfile /var/run/sshd.pid
# start program "/etc/init.d/ssh start"
# stop program "/etc/init.d/ssh stop"
# if failed port 2244 protocol ssh then restart
# ].lstrip
# 
#   push_text config_text, config_file
# 
#   verify do
#     file_contains config_file, "monit-ssh"
#   end

package :postgresql_roles do
  requires :postgresql_core
  
  # TODO
  
  verify do
  end
end

package :postgresql_config do
  requires :postgresql_core
  
  config_file = '/etc/postgresql/8.4/main/postgresql.conf'
  config_template = File.join(File.dirname(__FILE__), 'postgresql', 'postgresql.conf')

  transfer config_template, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
  end
  
  client_auth_config_file = '/etc/postgresql/8.4/main/pg_hba.conf'
  client_auth_config_template = File.join(File.dirname(__FILE__), 'postgresql', 'pg_hba.conf')

  transfer client_auth_config_template, client_auth_config_file, :render => false do
    pre :install, "touch #{client_auth_config_file} && rm #{client_auth_config_file} && touch #{client_auth_config_file}"
  end

  verify do
    has_file config_file
    has_file client_auth_config_file
    
    file_contains config_file, `head -n 1 #{config_template}`
    file_contains client_auth_config_file, `head -n 1 #{client_auth_config_file}`
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

package :postgresql_restart do
  requires :postgresql_core
  
  noop do
    pre :install, "/etc/init.d/postgresql restart"
  end
end
