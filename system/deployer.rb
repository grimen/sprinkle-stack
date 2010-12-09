
package :deployer, :provides => :deployer do
  description "Setup deployer (user/group)"
  
  requires :deploy_user, :deployer_id_rsa, :deployer_sudoers
  optional :deployer_capistrano_dirs
end

package :deployer_user do
  noop do
    # Create group "deployer".
    pre :install, "groupadd deployer"
    pre :install, "useradd -m -g #{deployer} deployer"
    
    # Copy SSH-keys from root.
    pre :install, "mkdir -p /home/#{deployer}/.ssh"
    pre :install, "touch /home/#{deployer}/.ssh/id_rsa"
    pre :install, "touch /home/#{deployer}/.ssh/id_rsa.pub"
    pre :install, "touch /home/#{deployer}/.ssh/known_hosts" # RSA
    # pre :install, "touch /home/#{deployer}/.ssh/known_hosts2" # DSA
    
    pre :install, "cp /root/.ssh/authorized_keys /home/#{deployer}/.ssh/authorized_keys" # RSA
    # pre :install, "cp /root/.ssh/authorized_keys2 /home/#{deployer}/.ssh/authorized_keys2" # RSA
    
    pre :install, "chown -R #{deployer}:deployer /home/#{deployer}/.ssh/"
    pre :install, "chmod 0600 /home/#{deployer}/.ssh/id_rsa"
  end

  verify do
    has_file "/home/#{deployer}/.ssh/id_rsa"
    has_file "/home/#{deployer}/.ssh/id_rsa.pub"
    has_file "/home/#{deployer}/.ssh/authorized_keys" # RSA
    # has_file "/home/#{deployer}/.ssh/authorized_keys2" # DSA
  end
end

package :deployer_capistrano_dirs do
  description "Create shared Capistrano paths (for deployer)"
  
  noop do
    pre :install, "mkdir -p #{deploy_to}/releases"
    pre :install, "mkdir -p #{deploy_to}/shared"
    pre :install, "mkdir -p #{deploy_to}/shared/config"
    pre :install, "mkdir -p #{deploy_to}/shared/log"
    pre :install, "mkdir -p #{deploy_to}/shared/pids"
    pre :install, "mkdir -p #{deploy_to}/shared/system"
    
    pre :install, "chown -R #{deployer}:deployer #{deploy_to}/"
    pre :install, "chmod -R ug=rwx #{deploy_to}/"
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

package :deployer_id_rsa do
  noop do
    # Ensure there is a .ssh folder.
    pre :install, "mkdir /home/#{deployer}/.ssh"
    
    # Set correct permissons and ownership.
    post :install, "chmod 0700 /home/#{deployer}/.ssh"
    post :install, "chown -R #{deployer}:deployer /home/#{deployer}/.ssh"
  end
  
  verify do
    has_directory "/home/#{deployer}/.ssh"
  end
  
  %w[id_rsa id_rsa.pub].each do |filename|
    id_rsa_file = "/home/#{deployer}/.ssh/#{filename}"
    local_id_rsa_file = File.join(ENV['HOME'], '.ssh', filename) # TODO: ask?

    transfer local_id_rsa_file, id_rsa_file, :render => false do
      # Set correct permissons.
      post :install, "chmod 0600 #{id_rsa_file}"
    end
    
    verify do
      has_file id_rsa_file
      file_contains id_rsa_file, `head -n 1 #{local_id_rsa_file}`
    end
  end
  
  noop do
    # Add deployer public key to authorized ones.
    post :install, "mv /home/#{deployer}/.ssh/id_rsa.pub /home/#{deployer}/.ssh/authorized_keys"
    post :install, "chmod 0700 /home/#{deployer}/.ssh/authorized_keys"
  end
  
  verify do
    file_contains id_rsa_file, id_rsa_text
  end
end

package :deployer_sudoers do
  config_file = '/etc/sudoers'
  config_text = File.read(File.join(File.dirname(__FILE__), 'deployer', 'deployer.sudoers.rules'))

  push_text config_text, config_file do
    post :install, "/etc/init.d/sudo restart"
  end

  verify do
    file_contains config_file, config_text
  end
end
