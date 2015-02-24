#
# Cookbook Name:: unblibraries-drupal
# Recipe:: drush
#
# Copyright 2015, UNB Libraries
#
execute "install_composer" do
  cwd "/root"
  command <<-EOH
       curl -sS https://getcomposer.org/installer | php
       mv composer.phar #{node['unblibraries-drupal']['drush']['composer-path']}
  EOH
end  

execute "install_drush" do
  user "#{node['unblibraries-drupal']['deploy-user']}"
  cwd "#{node['unblibraries-drupal']['deploy-user-home']}"
  command <<-EOH
       sed -i '1i export PATH="#{node['unblibraries-drupal']['deploy-user-home']}/.composer/vendor/bin:$PATH"' #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
       export PATH="#{node['unblibraries-drupal']['deploy-user-home']}/.composer/vendor/bin:$PATH"
       export HOME="#{node['unblibraries-drupal']['deploy-user-home']}"
       composer global require drush/#{node['unblibraries-drupal']['drush']['version']}
       drush dl registry_rebuild
  EOH
end
