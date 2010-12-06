
package :memcached, :provides => :cachestore do
  description "Memcached"

  requires :memcached_core, :memcached_config, :memcached_logrotate, :memchached_restart
end

package :memcached_core do
  apt 'memcached' do
    pre :install, "mkdir -p /var/log/memcached"
    post :install, "chown deployer:deployer -R /var/log/memcached"
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

package :memchached_restart do
  requires :memcached_core
  
  noop do
    pre :install, "/etc/init.d/memcached restart"
  end
end
