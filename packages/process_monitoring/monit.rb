
package :monit, :provides => :process_monitoring do
  description "Monit - system process monitoring"
  
  requires :monit_core, :monit_config, :monit_restart
end

package :monit_core do
  apt 'monit'

  verify do
    has_executable 'monit'
    
    has_file '/etc/init.d/monit'
    has_file '/etc/logrotate.d/monit'
  end
end

package :monit_config do
  requires :monit_core
  
  config_file = '/etc/monitrc'
  config_template = File.join(File.dirname(__FILE__), 'monit', 'monit.rc')
  
  transfer config_template, config_file, :render => true do
    # Ensure path exists.
    pre :install, "mkdir -p #{File.dirname(config_file)}"
    
    # Allow monit startup.
    post :install, "echo > /etc/default/monit 'startup=1'"
  end
  
  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end

package :monit_autostart do
  description "Monit: Autostart on reboot"
  requires :monit_core
  
  runner '/usr/sbin/update-rc.d monit default'
end

%w[start stop restart reload].each do |command|
  package :"monit_#{command}" do
    requires :monit_core

    runner "/etc/init.d/monit #{command}"
  end
end

%w(ssh memcached varnish nginx nginx_with_varnish).each do |process_name|
  package :"monit_#{process}" do
    config_file = '/etc/monitrc'
    config_template = File.join(File.dirname(__FILE__), 'monit', "monit.rc.#{process_name}")

    push_text File.read(config_template), config_file

    verify do
      file_contains config_file, `cat #{config_template}`
    end
  end
end
