package :zsh, :provides => :shell do
  description 'ZSH Shell (oh-my-zsh)'
  
  requires :zsh_core
  optional :zsh_oh_my_zsh
end

package :zsh_core do
  description 'ZSH Shell'
  
  apt 'zsh' do
    # Set ZSH as default shell.
    post :install, "chsh -s /bin/zsh"
  end
  
  verify do
    file_contains config_file, 'export ZSH=$HOME/.oh-my-zsh'
  end
end

package :zsh_oh_my_zsh do
  description 'oh-my-zsh - ZSH framework'
  
  config_file = "/home/#{deployer}/.zsh"
  
  install_files = {:root => '/root/.oh-my-zsh-installer', :skel => '/etc/skel/.oh-my-zsh-installer', :deployer => "/home/#{deployer}/.oh-my-zsh-installer"}
  install_template = File.join(File.dirname(__FILE__), 'zsh', 'oh-my-zsh-installer')
  
  install_files.each do |install_file|
    transfer install_template, install_file do
      # Allocate install file.
      pre :install, "touch #{install_file}"

      # Install ZSH framework "oh-my-zsh".
      post :install, "chmod +x #{install_file} && sh #{install_file}"
      # post :install, "rm #{install_file}"
    end

    verify do
      file_contains config_file, 'export ZSH=$HOME/.oh-my-zsh'
    end
  end
end

package :zsh_set_as_default_shell do
  description 'Set ZSH as default shell'
  
  noop 'zsh' do
    # Set ZSH as default shell.
    pre :install, "chsh -s /bin/zsh"
    pre :install, "echo $SHELL > /tmp/.shell_status"
  end
  
  verify do
    file_contains '/tmp/.shell_status', '/bin/zsh'
  end
end
