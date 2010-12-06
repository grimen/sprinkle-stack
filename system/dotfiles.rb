
package :dotfiles do
  description "Default dotfiles"
  
  requires :dot_aliases, :dot_profile
end

%w[aliases profiles].each do |name|
  package :"dotfile_#{name}" do
    description "~/.#{name}"

    dotfile = "%s/.#{name}"
    dotfile_template = File.join(File.dirname(__FILE__), 'dotfiles', "#{name}")
    
    dotfile_for_new_users = dotfile % '/etc/skel'
    transfer dotfile_template, config_file_for_new_users, :render => false
    
    dotfile_for_root = dotfile % '/root'
    transfer dotfile_template, config_file_for_root, :render => false
    
    dotfile_for_deployer = dotfile % '/home/deployer'
    transfer dotfile_template, config_file_for_user, :render => false do
      post :install, "chown deployer:deployer #{config_file_for_user}"
    end

    verify do
      has_file dotfile_for_new_users
      has_file dotfile_for_root
      has_file dotfile_for_deployer
      
      tag = `head -n 1 #{dotfile_template}`
      file_contains dotfile_for_new_users, tag
      file_contains dotfile_for_root, tag
      file_contains dotfile_for_deployer, tag
    end
  end
end
