#
# Cookbook Name:: unblibraries-drupal
# Recipe:: xhprof
#
# Copyright 2015, UNB Libraries
#
bash 'add_pear_xhprof' do
  code <<-EOH
    pear channel-update pear.php.net
  EOH
end

package ['php5-common', 'graphviz'] do
  action :install
end

bash 'pecl_install_xhprof' do
  code <<-EOH
    sudo pecl config-set preferred_state beta
    sudo pecl install xhprof
  EOH
end

directory "/tmp/xhprof" do
  owner 'root'
  group 'root'
  mode '0777'
  action :create
end

template '/etc/php5/apache2/conf.d/xhprof.ini' do
  source 'xhprof.ini.erb'
  mode '0755'
  owner 'root'
  group 'root'
end

template '/etc/apache2/conf-available/xhprof.conf' do
  source 'xhprof.conf.erb'
  mode '0755'
  owner 'root'
  group 'root'
  notifies :restart, 'service[apache2]', :delayed
end

bash 'add_devel_enable_xhprof' do
  user node['unblibraries-drupal']['deploy-user']
  cwd node['unblibraries-drupal']['deploy-path']
  code <<-EOH
    source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
    drush dl devel
    drush en devel
    drush vset devel_xhprof_enabled 1
    drush vset devel_xhprof_directory "/usr/share/php"
    drush vset devel_xhprof_url "/xhprof_html"
  EOH
end
