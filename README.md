# Capistrano DB sync
Tasks for database sync a staging and a development environment from a production database.

## Supported DB
Now this gem are supporting Postgresql.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'capistrano-db-sync', require: false
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install capistrano-db-sync
```

And add that line to your `Capfile`:
```ruby
require 'capistrano/db/sync'
```

## database.yml
You have to add credentials to your remote instances (and also allow remote connections to them). For a production database instance, it's strongly recommended to create a read-only user.
Just make sure that your app `config/database.yml` file looks like this:
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: 40
  timeout: 5000
  username: ...

development:
  <<: *default
  database: ...

staging:
  <<: *default
  database: ...
  host: ...
  username: ...
  password: ...

production:
  <<: *default
  database: ...
  host: ...
  username: ...
  password: ...
```

## deploy.rb configuration
```ruby
# directory (on a remote instance) to store dump before it will be downloaded
set :db_sync_dumps_path,                "#{shared_path}/db_dumps"
set :db_sync_download_path,             './tmp' # directory on your local mashine to store downloaded dump
set :db_sync_staging_before_sync_tasks, 'puma:stop' # capistrano tasks that will be executed on a staging environment before db sync
set :db_sync_staging_after_sunc_tasks,  'puma:start' # capistrano tasks that will be executed on a staging environment after db sync
```

## Staging sync workflow
During sync on a staging environment instances this gem will do following steps:
- stop web server using `db_sync_staging_before_sync_tasks`;
- drop a database;
- create a new database;
- migrate the database (note that there could be migrations on your staging environment that are not present yet in a production) using a capistrano `deploy:migrating` task;
- start web server using `db_sync_staging_after_sunc_tasks`. Feel free to add a `cache:clear` from https://github.com/piotr-kedziak/capistrano-cache to clear a cache.

## Usage
After installation, you can run a Capistrano task on any of yours environments stages:
```bash
cap production db:dump_production     # Create a dump from a production database
cap production db:load_into_localhost # Load a dump into a localhost database
cap production db:load_into_staging   # Load a dump into a staging database
cap production db:sync_all            # Synchronize database on a staging and a localhost
cap production db:sync_dev            # Synchronize development database on a localhost
cap production db:sync_staging        # Synchronize database on a staging instance
```

Remeber to use stage `production`!

## Contributing
1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
