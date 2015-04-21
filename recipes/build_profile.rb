#
# Cookbook Name:: unblibraries-drupal
# Recipe:: build_profile
#
# Copyright 2015, UNB Libraries
#
include_recipe 'unblibraries-drupal::prerequisites'

drush_bin='drush --yes --verbose'
profile_root_dir = "#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}/profiles/#{node['unblibraries-drupal']['install-profile-name']}"

template "#{Chef::Config[:file_cache_path]}/#{node['unblibraries-drupal']['install-profile-name']}.make" do
  source %W{ #{node['unblibraries-drupal']['install-profile-slug']}/makefile.erb }
  owner node['unblibraries-drupal']['deploy-user']
  group node['unblibraries-drupal']['deploy-user-group']
  mode '00755'
end

bash 'make_drupal_makefile' do
  user node['unblibraries-drupal']['deploy-user']
  cwd node['unblibraries-drupal']['deploy-path']
  code <<-EOH
    source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
    #{drush_bin} make #{Chef::Config[:file_cache_path]}/#{node['unblibraries-drupal']['install-profile-name']}.make --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --concurrency=1 --uri=default --no-cache #{node['unblibraries-drupal']['deploy-dir-name']}
  EOH
end

bash 'initialize_drupal_database' do
  user node['unblibraries-drupal']['deploy-user']
  cwd node['unblibraries-drupal']['deploy-user-home']
  code <<-EOH
    source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
    mysql -S /var/run/mysql-default/mysqld.sock -P3306 -u root -p#{node['unblibraries-mysql']['mysql']['server_root_password']} -e "CREATE DATABASE #{node['unblibraries-drupal']['db']['database']}"
    mysql -S /var/run/mysql-default/mysqld.sock -P3306 -u root -p#{node['unblibraries-mysql']['mysql']['server_root_password']} -e "GRANT ALL PRIVILEGES ON #{node['unblibraries-drupal']['db']['database']}.* TO '#{node['unblibraries-drupal']['db']['username']}'@'localhost' IDENTIFIED BY '#{node['unblibraries-drupal']['db']['password']}'"
    mysql -S /var/run/mysql-default/mysqld.sock -P3306 -u root -p#{node['unblibraries-mysql']['mysql']['server_root_password']} -e "FLUSH PRIVILEGES"
  EOH
end

directory profile_root_dir do
  owner node['unblibraries-drupal']['deploy-user']
  group node['unblibraries-drupal']['deploy-user-group']
  mode '0755'
  recursive true
  action :create
end

%w(info install profile).each do |profile_file_extension|
  template "#{profile_root_dir}/#{node['unblibraries-drupal']['install-profile-name']}.#{profile_file_extension}" do
    source %W{ #{node['unblibraries-drupal']['install-profile-slug']}/profile.#{profile_file_extension}.erb }
    owner node['unblibraries-drupal']['deploy-user']
    group node['unblibraries-drupal']['deploy-user-group']
    mode '00755'
  end
end

bash 'site_install_new_site' do
  user "#{node['unblibraries-drupal']['deploy-user']}"
  cwd "#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}"
  code <<-EOH
    source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
    # Deploy install profile to drupal tree
    #{drush_bin} site-install #{node['unblibraries-drupal']['install-profile-name']} --account-name=admin --account-pass=admin --db-url=mysql://#{node['unblibraries-drupal']['db']['user']}:#{node['unblibraries-drupal']['db']['password']}@localhost/#{node['unblibraries-drupal']['db']['database']}
  EOH
end
