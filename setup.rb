require File.expand_path('../base', __FILE__)

# Require all packages.
Dir[File.join('packages', '**', '*.rb')].each do |package|
  require package
end

# Stack setup.
policy :stack, :roles => :app do
  requires :root                    # Ensure root access (required)
  requires :tools                   # Common system tools and dependencies
  requires :ssh
  
  requires :deployer                # default: deployer/deployer
  requires :firewall                # iptables
  requires :shell                   # ZSH
  requires :scm                     # Git
  
  requires :ruby                    # RVM: REE + 1.9.2 + Bundler
  requires :appserver               # Passenger
  requires :webserver               # Nginx
  requires :mailserver              # Postfix
  requires :database                # MySQL or Postgres, also installs rubygems for each
  
  # requires :memorystore             # Memcached
  # requires :process_monitoring      # Monit
  # requires :http_proxy              # Varnish
  # requires :bruteforce_protection   # Fail2ban
  # requires :logrotate
  
  requires :cleanup
end

# Deployment procedure - and preferences.
deployment do
  # Mechanism for deployment.
  delivery :capistrano do
    begin
      recipes 'Capfile'
    rescue LoadError
      begin
        recipes 'deploy'
      rescue LoadError
      end
    end

    ssh_options[:forward_agent] = true
    default_run_options[:pty] = true
    
    vars = {
      :app      => {:label => ":app, host domain/IP",     :default => nil},
      :deployer => {:label => ":deployer, deploy-user",   :default => 'deployer'},
      :user     => {:label => ":root, setup-user",        :default => 'root'},
      :group    => {:label => ":group, deployers-group",  :default => 'deployer'}
    }
    
    # Ensure defined - if not, then ask.
    vars.keys.each do |var|
      unless defined?(var) || (value = send(var)).present?
        print "#{vars[var][:label]} (default: #{vars[var][:default]}): "
        value = gets || vars[var][:label]
        set var, value
      end
    end
    
    if app.blank?
      puts "[stack/setup.rb] No valid host specified for role :app. Needs to be a valid domain or IP. Specified: #{app.inspect}"
      exit
    end
    
    puts %{[IMPORTANT:] Amazon EC2 images by default don't allow logins as root, therefore login as user "ubuntu" (for Ubuntu, see docs for other distributions). To enable root login: (1) Login as default user, (2) switch to root, (3) remove the leading command-part in '/root/.ssh/authorized_keys' using an editor, (4) Ensure root password is set. Now it should work!}
  end

  # Source based package installer defaults.
  source do
    prefix   '/usr/local'
    archives '/usr/local/sources'
    builds   '/usr/local/build'
  end
end
