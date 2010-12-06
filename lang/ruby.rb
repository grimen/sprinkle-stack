
package :ruby, :provides => :ruby do
  description "Ruby (RVM)"
  
  requires :rvm, :ruby_ree, :ruby_19
  optional :bundler
end

# == References
#   - http://blog.ninjahideout.com/posts/a-guide-to-a-nginx-passenger-and-rvm-server
#   - http://blog.ninjahideout.com/posts/the-path-to-better-rvm-and-passenger-integration
#   - http://rvm.beginrescueend.com/integration/passenger

package :rvm do
  description "RVM - Ruby Version Manager"
  
  requires :ruby_dependencies
  
  noop do
    # Install RVM.
    post :install, 'bash < <( curl http://rvm.beginrescueend.com/releases/rvm-install-head )'
    post :install, 'rvm reload'
    
    # Add user to rvm group.
    post :install, 'adduser deployer rvm'
    
    # Update Rubygems (non-verbose).
    post :install, 'gem update --system > /dev/null 2>&1'
  end

  # Source RVM - automatically load RVM.
  profile = {:root => '/root/.profile', :skel => '/etc/skel/.profile', :deployer => '/home/deployer/.profile'}
  rvm_source_string = %{if groups | grep -q rvm ; then source "/usr/local/lib/rvm"; fi}
  push_text rvm_source_string, profile[:root]
  push_text rvm_source_string, profile[:skel]
  push_text rvm_source_string, profile[:deployer]
  
  # .gemrc
  gemrc = {:root => '/root/.gemrc', :skel => '/etc/skel/.gemrc', :deployer => '/home/deployer/.gemrc'}
  gemrc_template = File.join(File.dirname(__FILE__), 'ruby', '.gemrc')
  transfer gemrc_template, gemrc[:root], :render => false
  transfer gemrc_template, gemrc[:skel], :render => false
  transfer gemrc_template, gemrc[:deployer], :render => false
  
  # .rvmrc
  rvmrc = {:root => '/root/.rvmrc', :skel => '/etc/skel/.rvmrc', :deployer => '/home/deployer/.rvmrc'}
  rvmc_template = File.join(File.dirname(__FILE__), 'ruby', '.rvmrc')
  transfer rvmc_template, rvmrc[:root], :render => false
  transfer rvmc_template, rvmrc[:skel], :render => false
  transfer rvmc_template, rvmrc[:deployer], :render => false
  
  verify do
    has_executable 'rvm'
    has_executable 'ruby'
    has_executable 'gem'
    
    [:root, :skel, :deployer].each do |id|
      has_file gemrc[id]
      file_contains gemrc[id], "sprinkled: .gemrc v1"
      
      has_file rvmrc[id]
      file_contains rvmrc[id], "sprinkled: .rvmrc v1"
    end
    has_file gemrc[:root]
    
    file_contains profile_file_for_root, rvm_source_string
    file_contains profile_file_for_new_users, rvm_source_string
    file_contains profile_file_for_deployer, rvm_source_string
  end
end

package :ruby_dependencies do
  apt 'build-essential bison openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev autoconf'
end

package :ruby_ree do
  description "Ruby Enterprise Edition (REE)"
  
  requires :rvm
  
  noop do
    # Install REE.
    post :install, 'rvm install ree'
    
    # Set REE as current/default Ruby version.
    post :install, 'rvm use ree --default'
  end
end

package :ruby_19 do
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
