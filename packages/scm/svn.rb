
package :svn, :provides => :scm do
  description "Subversion (SVN)"
  
  requires :svn_core
end

package :svn_core do
  apt 'subversion'

  verify do
    has_executable 'svn'
  end
end
