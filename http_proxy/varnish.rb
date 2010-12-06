
package :varnish, :provides => :http_proxy do
  description "Varnish"
  
  requires :varnish_core, :varnish_config, :varnish_vcl, :varnished_restart
end

package :varnish_core do
  requires :varnish_dependencies
  
  apt 'varnish' do
    # post :install, "chown deployer:deployer -R /var/log/varnish"
  end

  verify do
    has_executable '/usr/sbin/varnishd'
  end
end

package :varnish_dependencies do
  apt 'autotools-dev automake1.9 libtool autoconf libncurses-dev xsltproc quilt'
end

package :varnish_config do
  requires :varnish_core
  
  config_file = '/etc/default/varnish'
  config_template = File.join(File.dirname(__FILE__), 'varnish', 'varnish.conf')

  transfer config_template, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end


package :varnish_vcl do
  requires :varnish_core
  
  config_file = '/etc/varnish/default.vcl'
  config_template = File.join(File.dirname(__FILE__), 'varnish', 'varnish.default.vcl')

  transfer config_template, config_file, :render => false do
    pre :install, "touch #{config_file} && rm #{config_file} && touch #{config_file}"
  end

  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :varnished_restart do
  requires :varnish_core
  
  noop do
    pre :install, "/etc/init.d/varnish restart"
  end
end
