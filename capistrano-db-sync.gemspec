$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'capistrano/db/sync/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'capistrano-db-sync'
  s.version     = Capistrano::Db::Sync::VERSION
  s.authors     = ['Piotr Kędziak']
  s.email       = ['piotr@kedziak.com']
  s.homepage    = 'https://github.com/piotr-kedziak/capistrano-db-sync'
  s.summary     = 'Tasks for database sync a staging and a development environments from a production database'
  s.description = 'Designed to allow you to copy whole production database to a staging and/or a development environment'
  s.license     = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.require_paths = ['lib']

  s.add_dependency 'capistrano', '>= 3.9.0'
  s.add_dependency 'rails', '>= 4.0.0'
end
