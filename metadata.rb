name             'unblibraries-drupal'
maintainer       'UNB Libraries Systems'
maintainer_email 'jsanford@unb.ca'
license          'All rights reserved'
description      'Drupal wrapper recipe for UNB Libraries'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends "unblibraries-apache2"
depends "database"
depends "unblibraries-casperjs"
depends "unblibraries-solr"
