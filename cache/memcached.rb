
package :memcached, :provides => :memorystore do
  description "Memcached"

  requires :memcached_core, :memcached_config, :memcached_logrotate, :memchached_restart
end

package :memcached_core do
  apt 'memcached' do
    pre :install, "mkdir -p /var/log/memcached"
    post :install, "chown deployer:deployer -R /var/log/memcached.log"
  end

  verify do
    has_executable 'memcached'
  end
end

package :memcached_config do
  requires :memcached_core
  
  config_file = '/etc/memcached.conf'
  config_template = File.join(File.dirname(__FILE__), 'memchached', 'memchached.conf')

  transfer config_template, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :memchached_logrotate do
  requires :logrotate
  
  config_file = '/etc/logrotate.d/memchached'
  config_template = File.join(File.dirname(__FILE__), 'memchached', 'memchached.logrotate.d')

  transfer config_template, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
    post :install, "chmod 0644 #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :memcached_autostart do
  requires :memcached_core
  
  noop do
    pre :install, '/usr/sbin/update-rc.d memcached default'
  end
  
  verify do
  end
end

%w[start stop restart reload].each do |command|
  package :"memcached_#{command}" do
    requires :memcached_core

    noop do
      pre :install, "/etc/init.d/memcached #{command}"
    end
  end
end
