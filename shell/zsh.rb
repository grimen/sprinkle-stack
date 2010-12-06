package :zsh, :provides => :shell do
  description 'ZSH Shell (oh-my-zsh)'
  
  config_file = "/home/deployer/.zsh"
  
  install_file = "/home/deployer/zsh-setup"
  install_file_text = File.read(File.join(File.dirname(__FILE__), 'zsh', 'setup'))
  
  push_text install_file_text, install_file do
    # Allocate install file.
    pre :install, "touch #{install_file}"
    
    # Install ZSH framework "oh-my-zsh".
    post :install, "chmod +x #{install_file} && sh #{install_file}"
    post :install, "rm #{install_file}"
    
    # Set ZSH as default shell.
    post :install, "chsh -s /bin/zsh"
  end
  
  verify do
    file_contains config_file, 'export ZSH=$HOME/.oh-my-zsh'
  end
end