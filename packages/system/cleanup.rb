
package :cleanup, :provides => :cleanup do
  description "Cleanup"
  
  requires :apt_clean, :update_db, :tmp_clean
  recommends :reboot
end

package :apt_clean do
  runner 'apt-get clean'
end

package :update_db do
  runner 'updatedb'
end

package :tmp_clean do
  runner 'find /tmp -mtime +1 -exec rm -rf {} \;'
end

package :reboot do
  runner 'reboot'
end