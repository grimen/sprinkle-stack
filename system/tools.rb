
package :tools, :provides => :tools do
  description "Common tools needed by applications or for operations"
  
  requires :build_essential, :ntp, :screen, :curl, :vim, :htop, :imagemagick
end

package :build_essential do
  apt 'build-essential' do
    pre :install, 'apt-get update'
  end
  
  verify do
    has_apt 'build-essential'
  end
end

package :ntp do
  apt 'ntp'
  
  post :install, 'ntpdate ntp.ubuntu.com'
  
  verify do
    has_executable 'ntpdate'
  end
end

package :screen do
  apt 'screen'
  
  verify do
    has_executable 'screen'
  end
end

package :curl do
  apt 'curl'

  verify do
    has_executable 'curl'
  end
end

package :vim do
  apt 'vim'

  verify do
    has_executable 'vim'
  end
end

package :htop do
  apt 'htop'

  verify do
    has_executable 'htop'
  end
end

package :imagemagick do
  apt 'imagemagick'
  
  verify do
    has_executable 'imagemagick'
  end
end
