#
# Cookbook Name:: unblibraries-drupal
# Recipe:: clone_existing
#
# Copyright 2015, UNB Libraries
#
include_recipe "unblibraries-drupal::prerequisites"
include_recipe "unblibraries-casperjs"

keys = Chef::DataBagItem.load("keys", "drupal")
if keys["deploy_key_private"]
  template "#{node['unblibraries-drupal']['deploy-user-home']}/.ssh/config" do
    source "ssh-config.erb"
    owner "#{node['unblibraries-drupal']['deploy-user']}"
    group "#{node['unblibraries-drupal']['deploy-user-group']}"
    mode "0600"
  end

  file "#{node['unblibraries-drupal']['deploy-user-home']}/.ssh/deploy_key" do
    content "#{keys['deploy_key_private']}\n"
    owner node['unblibraries-drupal']['deploy-user']
    group node['unblibraries-drupal']['deploy-user-group']
    mode '0600'
  end

  file "#{node['unblibraries-drupal']['deploy-user-home']}/.ssh/deploy_key.pub" do
    content "#{keys['deploy_key_public']}\n"
    owner node['unblibraries-drupal']['deploy-user']
    group node['unblibraries-drupal']['deploy-user-group']
    mode '0755'
  end

  drush_bin="drush --yes --verbose --include=#{node['unblibraries-drupal']['deploy-user-home']}/site-build/drush-scripts --alias-path=#{node['unblibraries-drupal']['deploy-user-home']}/site-build/aliases"
  uri_slug=node['unblibraries-drupal']['deploy-uri'].gsub '.', '_'

  bash "build_drupal_from_makefile" do
    user "#{node['unblibraries-drupal']['deploy-user']}"
    cwd "#{node['unblibraries-drupal']['deploy-user-home']}"
    code <<-EOH
      # Load drush Path from bashrc
      source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc

      # Clone site definition into working directory
      git clone git@github.com:unb-libraries/build-profile-#{node['unblibraries-drupal']['deploy-uri']}.git site-build
      cd site-build
      git checkout @#{node['unblibraries-drupal']['makefile-build-refspec']}

      # Before starting a build, ensure that we can connect to the remote site
      #{drush_bin} status @#{node['unblibraries-drupal']['deploy-uri']} --quiet

      # Build the site from the Makefile
      cd #{node['unblibraries-drupal']['deploy-path']}
      mkdir #{node['unblibraries-drupal']['deploy-dir-name']}
      cd #{node['unblibraries-drupal']['deploy-dir-name']}
      #{drush_bin} make #{node['unblibraries-drupal']['deploy-user-home']}/site-build/make/#{uri_slug}.makefile --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --concurrency=1 --uri=default --no-cache
    EOH
  end

  mysql_connection = ({
    :host => node['unblibraries-mysql']['mysql']['host'],
    :port => node['unblibraries-mysql']['mysql']['port'],
    :username => 'root',
    :password => node['unblibraries-mysql']['mysql']['server_root_password']})

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
    host node['unblibraries-mysql']['mysql']['host']
    action :grant
  end

  bash "initialize_drupal_database" do
    user "#{node['unblibraries-drupal']['deploy-user']}"
    cwd "#{node['unblibraries-drupal']['deploy-user-home']}/site-build/settings"
    code <<-EOH
      source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc

      # Modify and install the settings.php file
      sed -i "s/'database' => '.*',/'database' => '#{node['unblibraries-drupal']['db']['database']}',/g" settings.php
      sed -i "s/'username' => '.*',/'username' => '#{node['unblibraries-drupal']['db']['user']}',/g" settings.php
      sed -i "s/'password' => '.*',/'password' => '#{node['unblibraries-drupal']['db']['password']}',/g" settings.php
      sed -i "s/'host' => '.*',/'host' => '#{node['unblibraries-mysql']['mysql']['host']}',/g" settings.php
      sed -i "/\$base_url/d" settings.php
      rsync settings.php #{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}/sites/default
    EOH
  end

  bash "site_install_drupal_from_profile" do
    user "#{node['unblibraries-drupal']['deploy-user']}"
    cwd "#{node['unblibraries-drupal']['deploy-user-home']}/site-build/profiles"
    code <<-EOH
      source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
      # Deploy install profile to drupal tree
      rsync -r #{uri_slug} #{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}/profiles/

      # Install Site
      cd #{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}
      #{drush_bin} site-install #{uri_slug}
    EOH
  end

  bash "transfer_drupal_filesystem_from_remote" do
    user "#{node['unblibraries-drupal']['deploy-user']}"
    cwd "#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}"
    code <<-EOH
      source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
      # Transfer live files to Local
      # This must happen BEFORE the database sync, since the DB sync will alter
      # The target of the files using @self
      #{drush_bin} --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --uri=default rsync @#{node['unblibraries-drupal']['deploy-uri']}:%files @self:%files --omit-dir-times --no-p --no-o --exclude-paths="css:js:styles:imagecache:ctools:tmp"

      # Change File Path Permissions (TODO : Drush?)
      chmod -R 777 #{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}/sites/default/files
    EOH
  end

  bash "transfer_drupal_database_from_remote" do
    user "#{node['unblibraries-drupal']['deploy-user']}"
    cwd "#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}"
    code <<-EOH
      source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
      export HOME="#{node['unblibraries-drupal']['deploy-user-home']}"
      # Transfer live DB to Local
      #{drush_bin} --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --uri=default sql-sync @#{node['unblibraries-drupal']['deploy-uri']} @self

      # Set filepath var
      #{drush_bin} --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --uri=default vset file_public_path sites/default/files
      #{drush_bin} --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --uri=default vset file_private_path sites/default/files
      #{drush_bin} --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --uri=default vset file_temporary_path /tmp

      # Rebuild Registry
      #{drush_bin} --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --uri=default registry-rebuild
    EOH
  end

  bash "clear_local_drupal_cache" do
    user "#{node['unblibraries-drupal']['deploy-user']}"
    cwd "#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']}"
    code <<-EOH
      source #{node['unblibraries-drupal']['deploy-user-home']}/.bashrc
      # Clear Cache
      #{drush_bin} --root=#{node['unblibraries-drupal']['deploy-path']}/#{node['unblibraries-drupal']['deploy-dir-name']} --uri=default cc all
    EOH
  end

  bash "test_deployed_drupal" do
    user "#{node['unblibraries-drupal']['deploy-user']}"
    cwd "#{node['unblibraries-drupal']['deploy-user-home']}/site-build/tests"
    code <<-EOH
      if test -n "$(find #{node['unblibraries-drupal']['deploy-user-home']}/site-build/tests -maxdepth 1 -name '*.js' -print -quit)"
      then
        find . -type f -print0 | xargs -0 sed -i "s|{{URI_TO_TEST}}|#{node['unblibraries-drupal']['deploy-test-uri']}|g"
        casperjs --no-colors --direct test *.js
      fi
    EOH
  end

end
