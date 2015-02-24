#
# Cookbook Name:: unblibraries-drupal
# Recipe:: solr
#
# Copyright 2015, UNB Libraries
#
include_recipe "unblibraries-drupal::new"
include_recipe "solr"

drush_bin='drush --yes --verbose'

# Install remaining modules
node['unblibraries-drupal']['modules']['solr'].each do |mod|
  drupal_module mod do
    dir node['drupal']['dir']
    action :install
  end
end

# Download and Install solr modules
node['unblibraries-drupal']['modules']['solr'].each do |drupal_mod|
  bash 'download_enable_drupal_module_' + drupal_mod do
    user "#{node['unblibraries-drupal']['deploy-user']}"
    cwd "#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}"
    code <<-EOH
    source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
    # Deploy install profile to drupal tree
    #{drush_bin} dl #{drupal_mod}
    #{drush_bin} en #{drupal_mod}
    EOH
  end
end

# Remove default schema/config files
file "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/schema.xml" do
  action :delete
end

file "#{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/solrconfig.xml" do
  action :delete
end

# Copy Solr config from module
bash "copy_solr_libs" do
  user "root"
  cwd "/tmp"
  code <<-EOH
  cp -rf #{node['drupal']['dir']}/sites/all/modules/search_api_solr/solr-conf/4.x/* #{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/
  EOH
end
