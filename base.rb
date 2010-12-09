
# Require dependencies.

begin
  gem 'sprinkle', ">= 0.2.3"
rescue Gem::LoadError
  puts "sprinkle >= 0.2.3 required.\n Run: `gem install sprinkle`"
  exit
end

STACK_CONFIG = {}

module SprinkleStack
  module Verifiers
    module File
      def file_contains_not(path, text)
        @commands << "grep - '#{text}' #{path}"
      end
    end
    
    module Daemon
      def has_daemon(name)
        @commands << "test -f /etc/init.d/#{name}"
      end
    end
  end
end

Sprinle::Verify.register(SprinkleStack::Verifiers::File)
Sprinle::Verify.register(SprinkleStack::Verifiers::Daemon)
