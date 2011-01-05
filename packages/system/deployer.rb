
package :deployer, :provides => :deployer do
  description "Setup deployer (user/group)"
  
  requires :deploy_user, :deployer_ssh_keys, :deployer_enable_sudo
  
  if defined?(deploy_to) && deploy_to.present?
    recommends :deployer_app_dirs
  end
end

package :deployer_user do
  description "Deployer: Create user/group"
  
  noop do
    # Create: "deployer"-group.
    pre :install, "groupadd #{group}"
    
    # Create: "deployer"-user.
    pre :install, "useradd -m -g #{deployer} #{group}"
    
    # Copy SSH-keys from root.
    pre :install, "mkdir -p /home/#{deployer}/.ssh"
    pre :install, "cp /root/.ssh/id_rsa /home/#{deployer}/.ssh/id_rsa"
    pre :install, "cp /root/.ssh/id_rsa.pub /home/#{deployer}/.ssh/id_rsa.pub"
    pre :install, "cp /root/.ssh/known_hosts /home/#{deployer}/.ssh/known_hosts" # RSA
    
    # Copy authorized_keys from root.
    pre :install, "cp /root/.ssh/authorized_keys /home/#{deployer}/.ssh/authorized_keys" # RSA
    
    # Set proper permissions for deployer's copies.
    pre :install, "chown -R #{deployer}:#{group} /home/#{deployer}/.ssh/"
    pre :install, "chmod 0700 /home/#{deployer}/.ssh"
    pre :install, "chmod 0600 /home/#{deployer}/.ssh/id_rsa"
  end

  verify do
    has_file "/home/#{deployer}/.ssh/id_rsa"
    has_file "/home/#{deployer}/.ssh/id_rsa.pub"
    has_file "/home/#{deployer}/.ssh/authorized_keys" # RSA
  end
end

package :deployer_user_change_password do
  description "Change/Set deployer password"
  
  print "Enter a new deployer password: "
  new_user_password = gets || ''
  
  runner %{echo -e "#{new_user_password}\n#{new_user_password}" | passwd #{deployer}}

  verify do
  end
end

package :deployer_app_dirs do
  description "Deployer: Create shared deploy paths (for specified app if any)"
  requires :deployer_user
  
  noop do
    pre :install, "mkdir -p #{deploy_to}/releases"
    pre :install, "mkdir -p #{deploy_to}/shared"
    pre :install, "mkdir -p #{deploy_to}/shared/config"
    pre :install, "mkdir -p #{deploy_to}/shared/log"
    pre :install, "mkdir -p #{deploy_to}/shared/pids"
    pre :install, "mkdir -p #{deploy_to}/shared/system"
    
    pre :install, "chown -R #{deployer}:deployer #{deploy_to}"
    pre :install, "chmod -R ug=rwx #{deploy_to}"
  end

  verify do
    has_directory "#{deploy_to}/releases"
    has_directory "#{deploy_to}/shared"
    has_directory "#{deploy_to}/shared/config"
    has_directory "#{deploy_to}/shared/log"
    has_directory "#{deploy_to}/shared/pids"
    has_directory "#{deploy_to}/shared/system"
  end
end

package :deployer_ssh_keys do
  description "Deployer: SSH private/public keys"
  requires :deployer_user
  
  noop do
    # Ensure there is a .ssh folder.
    pre :install, "mkdir -p /home/#{deployer}/.ssh"
    
    # Set correct permissons and ownership.
    pre :install, "chmod 0700 /home/#{deployer}/.ssh"
    pre :install, "chown -R #{deployer}:deployer /home/#{deployer}/.ssh"
    
    # Add deployer public key to authorized ones.
    pre :install, "mv /home/#{deployer}/.ssh/id_rsa.pub /home/#{deployer}/.ssh/authorized_keys"
    pre :install, "chmod 0700 /home/#{deployer}/.ssh/authorized_keys"
  end
  
  verify do
    has_directory "/home/#{deployer}/.ssh"
  end
  
  %w[id_rsa id_rsa.pub].each do |filename|
    id_rsa_file = "/home/#{deployer}/.ssh/#{filename}"
    local_id_rsa_file = File.join(ENV['HOME'], '.ssh', filename) # TODO: ask?

    transfer local_id_rsa_file, id_rsa_file, :render => true do
      # Set correct permissons.
      post :install, "chmod 0600 #{id_rsa_file}"
    end
    
    verify do
      has_file id_rsa_file
      file_contains id_rsa_file, `cat #{local_id_rsa_file}`
    end
  end
end

package :deployer_enable_sudo do
  config_file = '/etc/sudoers'
  config_text = File.read(File.join(File.dirname(__FILE__), 'deployer', 'deployer.sudoers.rules'))

  push_text config_text, config_file do
    post :install, "/etc/init.d/sudo restart"
  end

  verify do
    file_contains config_file, config_text
  end
end
