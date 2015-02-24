#
# Cookbook Name:: unblibraries-drupal
# Recipe:: prerequisites
#
# Copyright 2015, UNB Libraries
#
include_recipe "unblibraries-users::sysadmin"
include_recipe "unblibraries-users::developers"
include_recipe "unblibraries-users::applications"
include_recipe "unblibraries-apache2"
include_recipe "unblibraries-drupal::drush"

package 'sendmail' do
  action :install
end

def run_bash(command_str)
  Kernel.system("/bin/bash", "-O", "e", "-c", command_str)
end

execute 'chown-www-docroot' do
  command "chown -R #{node['unblibraries-drupal']['deploy-user']}:#{node['unblibraries-drupal']['deploy-user-group']} #{node['unblibraries-drupal']['deploy-path']}"
  user "root"
  action :run
end

execute 'remove-deploy-location' do
  command "rm -rf #{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}"
  user "root"
  action :run
end

web_app 'drupal' do
  template "drupal.conf.erb"
  docroot node['unblibraries-drupal']['deploy-path'] + '/' + node['unblibraries-drupal']['deploy-dir-name']
  server_name node['fqdn']
end

cron 'drupal hourly cron' do
  command "cd #{node['unblibraries-drupal']['deploy-path']}; drush --yes core-cron"
  minute "0"
end

execute 'disable-default-site' do
  command "sudo a2dissite 000-default"
  notifies :reload, resources(:service => "apache2"), :delayed
end
