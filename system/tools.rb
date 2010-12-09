
package :tools, :provides => :tools do
  description "Tools: Common tools needed by applications or for operations"

  requires :build_essential, :ntp, :screen, :curl, :vim, :htop, :imagemagick, :rsync
end

package :build_essential do
  description 'build_essential'
  
  apt 'build-essential'

  verify do
    has_apt 'build-essential'
  end
  
  post :install, 'apt-get update'
end

package :ntp do
  description 'ntp'
  
  apt 'ntp'

  verify do
    has_executable 'ntpdate'
  end
  
  post :install, 'ntpdate ntp.ubuntu.com'
end

package :screen do
  description 'screen'
  
  apt 'screen'

  verify do
    has_executable 'screen'
  end
end

package :curl do
  description 'curl'
  
  apt 'curl'

  verify do
    has_executable 'curl'
  end
end

package :vim do
  description 'vim'
  
  apt 'vim'
  
  verify do
    has_executable 'vim'
  end
end

package :htop do
  description 'htop'
  
  apt 'htop'
  
  verify do
    has_executable 'htop'
  end
end

package :imagemagick do
  description 'imagemagick'
  
  apt 'imagemagick'
  
  verify do
    has_executable '/usr/bin/convert'
  end
end

package :rsync do
  description 'rsync'

  apt 'rsync'

  verify do
    has_executable 'rsync'
  end
end

