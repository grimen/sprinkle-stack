
package :mysql, :provides => :database do
  description 'MySQL Database'

  requires :mysql_core, :mysql_config, :mysql_iptable, :mysql_roles, :mysql_root_password, :mysql_restart
  optional :mysql_remote_access, :mysql_rubygem
end

package :mysql_core do
  # version '5.1'
  
  apt 'mysql-server mysql-client libmysqlclient-dev' do
    # post :install, "chown deployer:deployer -R /var/log/mysql"
  end

  verify do
    has_executable 'mysql'
  end
end

package :mysql_root_password do
  requires :mysql_core
  
  # TODO
  
  verify do
  end
end

package :mysql_iptable_rules do
  requires :mysql_core
  
  # TODO
  
  verify do
  end
end

package :mysql_roles do
  requires :mysql_core
  
  # TODO
  
  verify do
  end
end

package :mysql_config do
  requires :mysql_core
  
  # TODO
  
  verify do
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

package :mysql_restart do
  requires :mysql_core
  
  noop do
    pre :install, "/etc/init.d/mysql restart"
  end
end
