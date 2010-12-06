
package :cleanup, :provides => :cleanup do
  requires :apt_clean, :update_db
end

package :apt_clean do
  noop do
    pre :install, 'apt-get clean'
  end
end

package :update_db do
  noop do
    pre :install, 'update_db'
  end
end
