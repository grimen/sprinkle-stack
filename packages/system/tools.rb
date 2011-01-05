
package :tools, :provides => :tools do
  description "Tools: Common tools needed by applications or for operations"

  requires :build_essential, :ntp, :screen, :curl, :vim, :htop,
            :imagemagick, :rsync, :debconf_utils
end

package :build_essential do
  description 'build_essential'
  
  apt 'build-essential' do
    post :install, 'apt-get update && apt-get -y upgrade'
  end

  verify do
    has_apt 'build-essential'
  end
end

package :debconf_utils do
  description 'debconf-utils'
  
  apt 'debconf-utils'

  verify do
    has_executable 'debconf-get-selections'
  end
end

package :ntp do
  description 'ntp'
  
  apt 'ntp' do
    post :install, 'ntpdate ntp.ubuntu.com'
  end

  verify do
    has_executable 'ntpdate'
  end
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

# == References: EC2
#   - https://help.ubuntu.com/community/EC2StartersGuide

package :ec2_tools do
  description 'Amazon EC2 Tools'

  apt 'ec2-ami-tools ec2-api-tools'

  verify do
    has_directory '/etc/ec2'
  end
end
