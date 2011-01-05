
package :varnish, :provides => :http_proxy do
  description "Varnish - HTTP proxy"
  
  requires :varnish_core, :varnish_config, :varnish_vcl, :varnished_restart
end

package :varnish_core do
  requires :varnish_dependencies
  
  apt 'varnish' do
    post :install, "chown -R #{deployer}:#{group} /var/log/varnish"
  end

  verify do
    has_executable '/usr/sbin/varnishd'
    
    has_file '/etc/logrotate.d/varnish'
  end
end

package :varnish_dependencies do
  apt 'autotools-dev automake1.9 libtool autoconf libncurses-dev xsltproc quilt'
end

package :varnish_config do
  description "Varnish: Config"
  requires :varnish_core
  
  config_file = '/etc/default/varnish'
  config_template = File.join(File.dirname(__FILE__), 'varnish', 'varnish.default.conf')

  transfer config_template, config_file, :render => true do
    # Ensure path exists.
    pre :install, "mkdir -p #{File.dirname(config_file)}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :varnish_vcl do
  description "Varnish: Default VCL"
  requires :varnish_core
  
  config_file = '/etc/varnish/default.vcl'
  config_template = File.join(File.dirname(__FILE__), 'varnish', 'varnish.default.vcl')

  transfer config_template, config_file, :render => true do
    # Ensure path exists.
    pre :install, "mkdir -p #{File.dirname(config_file)}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :varnish_autostart do
  description "Varnish: Autostart on reboot"
  requires :varnish_core
  
  noop do
    pre :install, '/usr/sbin/update-rc.d varnish default'
  end
  
  verify do
  end
end

%w[start stop restart reload].each do |command|
  package :"varnish_#{command}" do
    requires :varnish_core

    noop do
      pre :install, "/etc/init.d/varnish #{command}"
    end
  end
end
