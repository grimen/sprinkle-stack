
package :ruby, :provides => :ruby do
  description "Ruby (RVM)"
  
  requires :ruby_core, :rvm, :rvm_ree, :rvm_ruby_19, :bundler
end

# == References
#   - http://blog.ninjahideout.com/posts/a-guide-to-a-nginx-passenger-and-rvm-server
#   - http://blog.ninjahideout.com/posts/the-path-to-better-rvm-and-passenger-integration
#   - http://rvm.beginrescueend.com/integration/passenger
#   - http://rvm.beginrescueend.com/deployment/best-practices/
#   - http://rvm.beginrescueend.com/workflow/scripting

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

package :rvm do
  description "RVM - Ruby Version Manager"
  
  requires :ruby_core
  
  apt 'ruby-full' do
    # Install RVM.
    post :install, 'bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-head )'
    post :install, 'rvm reload'
    
    # Add deployer to rvm group (root added already by RVM installer).
    post :install, %Q{adduser #{deployer} rvm}
    
    # Update Rubygems (non-verbose).
    post :install, 'gem update --system > /dev/null 2>&1'
    
    # Save RVM status (for verification).
    post :install, 'type rvm | head -n1 > /tmp/.rvm_status'
  end
  
  bashrc_replace_text = {'[ -z "$PS1" ] && return' => 'if [[ -n "$PS1" ]]; then'}
  bashrc_append_text = %{
fi
if groups | grep -q rvm ; then
  source "/usr/local/lib/rvm"
fi
  }
  replace_text replace_text.keys.first, replace_text.values.first, "/home/#{deployer}/.bashrc"
  push_text bashrc_append_text, "/home/#{deployer}/.bashrc"

  # Source RVM - automatically load RVM.
  profile = {:root => '/root/.profile', :skel => '/etc/skel/.profile', :deployer => "/home/#{deployer}/.profile"}
  rvm_source_string = %{if groups | grep -q rvm ; then source "/usr/local/lib/rvm"; fi}
  push_text rvm_source_string, profile[:root]
  push_text rvm_source_string, profile[:skel]
  push_text rvm_source_string, profile[:deployer]
  
  # .gemrc
  gemrc = {:root => '/root/.gemrc', :skel => '/etc/skel/.gemrc', :deployer => "/home/#{deployer}/.gemrc"}
  gemrc_template = File.join(File.dirname(__FILE__), 'ruby', '.gemrc')
  transfer gemrc_template, gemrc[:root], :render => false
  transfer gemrc_template, gemrc[:skel], :render => false
  transfer gemrc_template, gemrc[:deployer], :render => false
  
  # .rvmrc
  rvmrc = {:root => '/root/.rvmrc', :skel => '/etc/skel/.rvmrc', :deployer => "/home/#{deployer}/.rvmrc"}
  rvmc_template = File.join(File.dirname(__FILE__), 'ruby', '.rvmrc')
  transfer rvmc_template, rvmrc[:root], :render => false
  transfer rvmc_template, rvmrc[:skel], :render => false
  transfer rvmc_template, rvmrc[:deployer], :render => false
  
  verify do
    file_contains '/tmp/.rvm_status', "rvm is a function"
    
    file_contains "/home/#{deployer}/.bashrc", bashrc_replace_text.values.first
    file_contains "/home/#{deployer}/.bashrc", bashrc_append_text
    
    [:root, :skel, :deployer].each do |id|
      has_file profile[id]
      file_contains profile[id], "sprinkled: .profile v1"
      
      has_file gemrc[id]
      file_contains gemrc[id], "sprinkled: .gemrc v1"
      
      has_file rvmrc[id]
      file_contains rvmrc[id], "sprinkled: .rvmrc v1"
    end
    
    file_contains profile_file_for_root, rvm_source_string
    file_contains profile_file_for_new_users, rvm_source_string
    file_contains profile_file_for_deployer, rvm_source_string
  end
end

package :rvm_ree do
  description "Ruby Enterprise Edition (REE)"
  
  requires :rvm
  
  noop do
    # Install REE.
    post :install, 'rvm install ree'
    
    # Set REE as current/default Ruby version.
    post :install, 'rvm use ree --default'
  end
end

package :rvm_ruby_19 do
  description "Ruby 1.9.2 (YARV)"
  version '1.9.2'
  
  requires :rvm
  
  noop do
    # Install Ruby 1.9.
    post :install, 'rvm install 1.9.2'
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
