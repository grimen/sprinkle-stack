
package :passenger, :provides => :appserver do
  description 'Phusion Passenger'
  version '3.0.0'
  
  requires :ruby
  
  binaries = %w[passenger-config passenger-install-nginx-module passenger-install-apache2-module passenger-make-enterprisey passenger-memory-stats passenger-spawn-server passenger-status passenger-stress-test]
  
  gem 'passenger', :version => version

  verify do
    has_gem 'passenger', version
    
    binaries.each do |bin|
      has_executable bin
    end
  end
end
