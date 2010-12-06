# Depend on a specific version of sprinkle.
begin
  gem 'sprinkle', ">= 0.2.3"
rescue Gem::LoadError
  puts "sprinkle >= 0.2.3 required.\n Run: `gem install sprinkle`"
  exit
end

# Require the stack base.
require 'system/tools'
require 'system/deployer'
require 'system/ssh'
require 'system/iptables'
require 'system/logrotate'
require 'system/dotfiles'
require 'system/cleanup'
require 'shell/zsh'
require 'scm/git'
require 'lang/ruby'
require 'appserver/passenger'
require 'webserver/nginx'
require 'mailserver/postfix'
require 'database/postgresql'
require 'cache/memcached'
require 'process_monitoring/monit'
require 'http/varnish'

# Stack setup.
policy :stack, :roles => :app do
  requires :tools
  requires :deployer
  requires :ssh
  # TODO: requires :ssl
  requires :firewall
  requires :dotfiles
  
  requires :shell                   # ZSH
  requires :scm                     # Git
  requires :ruby                    # RVM: REE + 1.9.2
  requires :bundler                 # Bundler
  requires :appserver               # Passenger
  requires :webserver               # Nginx
  requires :mailserver              # Postfix
  requires :database                # MySQL or Postgres, also installs rubygems for each
  requires :http_proxy              # Varnish
  # requires :process_monitoring      # Monit
  # requires :bruteforce_protection   # Fail2ban
  requires :cachestore              # Memcached
  
  requires :logrotate
  
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

    # Ensure defined.
    [:app, :user, :group].each { |var| set var, nil unless defined?(var) }

    # Name of deploying user (specified in deploy.rb); used to generate environment.
    set :deployer, (user || 'deployer')
    set :group, (group || 'deployer')

    # Setup the system as root (override deploy.rb).
    set :user, 'root'

    # Use specified host/IP if any.
    role :app, ARGV.first if ARGV.first.present?
  end

  # Source based package installer defaults.
  source do
    prefix   '/usr/local'
    archives '/usr/local/sources'
    builds   '/usr/local/build'
  end
end
