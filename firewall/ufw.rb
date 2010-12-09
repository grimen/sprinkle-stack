
package :ufw, :provides => :firewall do
  description "uwf - Uncomplicated Firewall"
  
  requires :ufw_core, :ufw_autostart
end

package :ufw_core do
  requires :curl
  
  open_ports = %w(80 443 22 25) # HTTP, HTTPS, SSH, SMTP

  apt 'ufw' do
    post :install, "ufw default deny"
    open_ports.each do |port|
      post :install, "ufw allow to 0.0.0.0/0 port #{port}"
    end
    post :install, "ufw enable"
    post :install, "ufw logging on"
    
    open_ports.each do |port|
      post :install, "curl localhost:#{port} > /tmp/ufw.port.#{port}.test"
    end
  end
  
  verify do
    file_contains_not "/tmp/ufw.port.#{port}.test", "couldn't connect to host"
  end
end

package :ufw_autostart do
  requires :ufw_core

  noop do
    pre :install, "update-rc.d ufw defaults"
  end
end

%w[start stop restart reload].each do |command|
  package :"ufw_#{command}" do
    requires :ufw_core

    noop do
      pre :install, "/etc/init.d/ufw #{command}"
    end
  end
end
