
package :sqlite3, :provides => :database do
  description "SQLite"
  
  apt 'sqlite3 libsqlite3-dev libsqlite3-ruby1.8'

  verify do
    has_executable 'sqlite3'
  end
end
