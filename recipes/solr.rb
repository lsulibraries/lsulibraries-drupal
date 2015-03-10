#
# Cookbook Name:: unblibraries-drupal
# Recipe:: solr
#
# Copyright 2015, UNB Libraries
#
include_recipe 'unblibraries-drupal::standard'

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
  cp -rf #{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}/sites/all/modules/search_api_solr/solr-conf/4.x/* #{node['solr']['installpath']}/#{node['solr']['core_name']}/conf/
  EOH
end
