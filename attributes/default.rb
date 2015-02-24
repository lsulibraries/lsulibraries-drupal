# Basic configuration
default['unblibraries-drupal']['deploy-uri'] = ''
default['unblibraries-drupal']['deploy-path'] = '/var/www'
default['unblibraries-drupal']['deploy-dir-name'] = 'html'
default['unblibraries-drupal']['deploy-user'] = 'mrrobot'
default['unblibraries-drupal']['deploy-user-group'] = 'mrrobot'
default['unblibraries-drupal']['deploy-user-home'] = '/home/mrrobot'
default['unblibraries-drupal']['deploy-test-uri'] = 'http://localhost/'

default['unblibraries-drupal']['drush']['composer-path'] = '/usr/local/bin/composer'
default['unblibraries-drupal']['drush']['version'] = 'drush:6.*'

default['unblibraries-drupal']['db']['database'] = 'drupal'
default['unblibraries-drupal']['db']['user'] = 'drupal'
default['unblibraries-drupal']['db']['password'] = 'drupal'

default['unblibraries-drupal']['install-profile-slug'] = 'default'

## Site Clone
# Refspec of the site profile repo to build.
default['unblibraries-drupal']['makefile-build-refspec'] = 'HEAD'
