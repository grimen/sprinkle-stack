
# TODO: Test if this works...
package :root, :provides => :root do
  description "Root access"
  
  requires :root_login
  recommends :root_authorize_public_key, :root_change_password
end

package :root_login do
  description "Login as root - if not already"
  
  # Ensure root access.
  runner 'sudo sh -'
  
  verify do
  end
end

package :root_change_password do
  description "Change/Set root password"
  requires :root_login
  
  print "Enter a new system root password: "
  new_root_password = gets || ''
  
  runner %{echo -e "#{new_root_password}\n#{new_root_password}" | passwd}

  verify do
  end
end

package :root_authorize_public_key do
  description "Upload/Authorize public key (from current client/deployer)"
  requires :root_login
  
  public_key_file = '/tmp/id_rsa.pub'
  local_public_key_file = File.join(ENV['HOME'], '.ssh', 'id_rsa.pub')
  
  print "Public key file (default: #{local_public_key_file}): "
  local_public_key_file = gets || local_public_key_file
  
  transfer local_public_key_file, public_key_file do
    pre :install, 'mkdir /root/.ssh'
    pre :install, 'chmod 0700 /root/.ssh'
    
    pre :install, "touch /root/.ssh/authorized_keys"
    pre :install, "chmod 0700 /root/.ssh/authorized_keys"
    
    post :install, "cat #{public_key_file} >> /root/.ssh/authorized_keys"
  end
  
  verify do
  end
end

package :root_upload_pem do
  description "Upload PEM-file"
  requires :root_login
  
  local_pem_file = nil # no guess by default
  
  print "PEM-file (default: #{local_public_key_file}): "
  local_pem_file = gets || local_pem_file
  while local_public_key_file.blank?
    local_pem_file = gets
  end
  pem_file = "/root/#{File.basename(local_pem_file)}"
  
  transfer local_pem_file, pem_file
  
  verify do
    has_file pem_file
    file_contains pem_file, `cat #{local_pem_file}`
  end
end
