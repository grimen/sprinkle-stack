
package :memcached, :provides => :memorystore do
  description "Memcached"

  requires :memcached_core, :memcached_config, :memcached_logrotate, :memchached_restart
end

package :memcached_core do
  apt 'memcached' do
    pre :install, "mkdir -p /var/log/memcached"
    post :install, "chown -R #{deployer}:#{group} /var/log/memcached"
  end

  verify do
    has_executable 'memcached'
  end
end

package :memcached_config do
  description "Memcached: Config"
  requires :memcached_core
  
  config_file = '/etc/memcached.conf'
  config_template = File.join(File.dirname(__FILE__), 'memcached', 'memcached.conf')

  transfer config_template, config_file, :render => true

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :memchached_logrotate do
  description "Memcached: Log rotation"
  requires :logrotate
  
  config_file = '/etc/logrotate.d/memcached'
  config_template = File.join(File.dirname(__FILE__), 'memcached', 'memcached.logrotate.d')

  transfer config_template, config_file, :render => true do
    post :install, "chmod 0644 #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :memcached_autostart do
  description "Memcached: Autostart on reboot"
  requires :memcached_core
  
  runner '/usr/sbin/update-rc.d memcached default'
  
  verify do
  end
end

%w[start stop restart reload].each do |command|
  package :"memcached_#{command}" do
    requires :memcached_core

    runner "/etc/init.d/memcached #{command}"
  end
end
