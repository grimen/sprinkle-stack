package :ruby, :provides => :ruby do
  description "Ruby (RVM)"
  
  requires :ruby_core, :rvm, :rvm_dotfiles, :rvm_ree, :rvm_ruby_19, :bundler
end

package :ruby_core do
  requires :ruby_dependencies
  
  apt 'ruby-full' do
    post :install, 'ln -s /usr/bin/ruby1.8 /usr/bin/ruby'
    post :install, 'ln -s /usr/bin/irb1.8 /usr/bin/irb'
    post :install, 'ln -s /usr/bin/rdoc1.8 /usr/bin/rdoc'
    post :install, 'ln -s /usr/bin/ri1.8 /usr/bin/ri'
    post :install, 'ln -s /usr/bin/gem1.8 /usr/bin/gem'
  end
  
  verify do
    has_symlink '/usr/bin/ruby', '/usr/bin/ruby1.8'
    has_symlink '/usr/bin/irb', '/usr/bin/irb1.8'
    has_symlink '/usr/bin/rdoc', '/usr/bin/rdoc1.8'
    has_symlink '/usr/bin/ri', '/usr/bin/ri1.8'
    has_symlink '/usr/bin/gem', '/usr/bin/gem1.8'
    
    has_executable 'ruby'
    has_executable 'irb'
    has_executable 'rdoc'
    has_executable 'ri'
    has_executable 'gem'
  end
end

package :ruby_dependencies do
  apt 'build-essential bison openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev autoconf'
end

# == RVM: References
#   - http://blog.ninjahideout.com/posts/a-guide-to-a-nginx-passenger-and-rvm-server
#   - http://blog.ninjahideout.com/posts/the-path-to-better-rvm-and-passenger-integration
#   - http://rvm.beginrescueend.com/integration/passenger
#   - http://rvm.beginrescueend.com/deployment/best-practices/
#   - http://rvm.beginrescueend.com/workflow/scripting

package :rvm do
  description "RVM - Ruby Version Manager"
  
  requires :ruby_core
  
  apt 'ruby-full' do
    # Install RVM.
    post :install, 'bash < <( curl -L https://github.com/wayneeseguin/rvm/raw/master/contrib/install-system-wide )'
    post :install, 'rvm reload'
    
    # Add deployer to rvm group (root added already by RVM installer).
    post :install, %Q{adduser #{deployer} rvm}
    
    # Update Rubygems (non-verbose).
    post :install, 'gem update --system > /dev/null 2>&1'
    
    # Save RVM status (for verification).
    post :install, 'type rvm | head -n1 > /tmp/.rvm_status'
  end
  
  bashrc_replace_text = {
    '[ -z "$PS1" ] && return' => 'if [[ -n "$PS1" ]]; then'
  }
  bashrc_append_text = 'fi'
  source_rvm_script = File.read(File.join(File.dirname(__FILE__), 'ruby', 'source_rvm.sh'))
  
  # Patch .basrc to load RVM properly.
  replace_text replace_text.keys.first, replace_text.values.first, "/home/#{deployer}/.bashrc"
  push_text bashrc_append_text, "/home/#{deployer}/.bashrc"
  
  # Source RVM - automatically load RVM (should work for most shells; bash, zsh, ...).
  push_text source_rvm_script, "/etc/skel/#{deployer}/.profile" do
    # Ensure file/path exists.
    pre :install, 'mkdir /etc/skel && touch /etc/skel/.profile'
    
    # Create: /root/.profile
    post :install, "cp /etc/skel/.profile /root/.profile"

    # Create: /home/deployer/.profile
    post :install, "cp /etc/skel/.profile /home/#{deployer}/.profile"
    post :install, "chown #{deployer}:#{group} /home/#{deployer}/.profile"
  end
  
  verify do
    # Ensure RVM binary was setup properly: should be a function, not a executable.
    file_contains '/tmp/.rvm_status', "rvm is a function"
    
    # Ensure ~/.bashrc was patched to work with RVM.
    file_contains "/home/#{deployer}/.bashrc", bashrc_replace_text.values.first
    file_contains "/home/#{deployer}/.bashrc", bashrc_append_text
    
    # Ensure RVM is sourced in ~/.profile.
    ['/etc/skel', '/root', "/home/#{deployer}"].each do |path|
      has_file "#{path}/.profile"
      file_contains "#{path}/.profile", source_rvm_script
    end
  end
end

package :rvm_dotfiles do
  requires :rvm
  
  %w(gemrc rvmrc).each do |dotfile|
    dotfile_template = File.join(File.dirname(__FILE__), 'ruby', ".#{dotfile}")
    
    # Create: /etc/skel/.gemrc
    transfer config_template, "/etc/skel/.#{dotfile}", :render => true do
      # Ensure path exists.
      pre :install, 'mkdir /etc/skel'
      
      # Create: /root/.gemrc
      post :install, "cp /etc/skel/.#{dotfile} /root/.#{dotfile}"

      # Create: /home/deployer/.gemrc
      post :install, "cp /etc/skel/.#{dotfile} /home/#{deployer}/.#{dotfile}"
      post :install, "chown #{deployer}:#{group} /home/#{deployer}/.#{dotfile}"
    end
    
    verify do
      ['/etc/skel', '/root', "/home/#{deployer}"].each do |path|
        has_file "#{path}/.#{dotfile}"
        file_contains "#{path}/.#{dotfile}", `head -n 1 #{dotfile_template}`
      end
    end
  end
end

package :rvm_ree do
  description "Ruby Enterprise Edition (REE)"
  
  requires :rvm
  
  noop do
    # Install REE.
    pre :install, 'rvm install ree'
    
    # Set REE as current/default Ruby version.
    post :install, 'rvm use ree --default'
  end
end

package :rvm_ruby_19 do
  description "Ruby 1.9.2"
  version '1.9.2'
  
  requires :rvm
  
  noop do
    # Install Ruby 1.9.
    pre :install, 'rvm install 1.9.2'
  end
end

package :bundler do
  description "Bundler - Ruby dependency manager"
  
  requires :rvm
  
  gem 'bundler'
  
  verify do
    has_executable 'bundle'
  end
end
