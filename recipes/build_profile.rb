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


mysql_connection = ({
  :host => node['mysql']['bind_address'],
  :username => 'root',
  :password => node['mysql']['server_root_password']})

mysql_database node['unblibraries-drupal']['db']['database'] do
  connection mysql_connection
  encoding 'utf8'
  collation 'utf8_unicode_ci'
  action :create
end

mysql_database_user node['unblibraries-drupal']['db']['user'] do
  connection mysql_connection
  password node['unblibraries-drupal']['db']['password']
  action :create
end

mysql_database_user node['unblibraries-drupal']['db']['user'] do
  connection mysql_connection
  password node['unblibraries-drupal']['db']['password']
  database_name node['unblibraries-drupal']['db']['database']
  host node['mysql']['bind_address']
  action :grant
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
