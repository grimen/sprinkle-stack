# sprinkled: mysql.grants.sql v1

# Create database user: '<%= deployer %>'
CREATE USER '<%= deployer %>'@'localhost' IDENTIFIED BY '<%= deployer_db_password %>';

# Create app databases
CREATE DATABASE <%= db_name %>_production CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE <%= db_name %>_staging CHARACTER SET utf8 COLLATE utf8_general_ci;
CREATE DATABASE <%= db_name %>_test CHARACTER SET utf8 COLLATE utf8_general_ci;

# Grant database privileges
GRANT ALL PRIVILEGES ON <%= db_name %>_production.* TO '<%= db_user %>'@'%';
GRANT ALL PRIVILEGES ON <%= db_name %>_staging.* TO '<%= db_user %>'@'%';
GRANT ALL PRIVILEGES ON <%= db_name %>_test.* TO '<%= db_user %>'@'%';

# Reload
FLUSH PRIVILEGES;