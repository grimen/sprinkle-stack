# sprinkled: postgresql.grants.sql v1

# Create database user: <%= deployer %>
CREATE ROLE <%= deployer %> WITH LOGIN ENCRYPTED PASSWORD '<%= deployer_db_password %>';

# Create app databases - with owner '<%= deployer %>'
CREATE DATABASE <%= db_name %>_production WITH OWNER <%= deployer %> ENCODING 'UTF8';
CREATE DATABASE <%= db_name %>_staging WITH OWNER <%= deployer %> ENCODING 'UTF8';
CREATE DATABASE <%= db_name %>_test WITH OWNER <%= deployer %> ENCODING 'UTF8';
