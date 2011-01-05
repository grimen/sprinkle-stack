
package :logrotate, :provides => :logrotate do
  description "Logrotate - system log rotation"
  
  requires :logrotate_core
  optional :logrotate_app_example
end

package :logrotate_core do
  apt 'logrotate'

  verify do
    has_executable 'logrotate'
  end
end

package :logrotate_app_example do
  description "Logrotate: Logrotation example (for apps)"
  
  config_file = "/etc/logrotate.d/app.example"
  config_template = File.read(File.join(File.dirname(__FILE__), 'logrotate', 'app.logrotate.conf'))

  transfer config_template, config_file, :render => true do
    post :install, "chmod 0644 #{config_file}"
  end
  
  verify do
    has_file config_file
    file_contains config_file, `head -n 1 #{config_template}`
  end
end