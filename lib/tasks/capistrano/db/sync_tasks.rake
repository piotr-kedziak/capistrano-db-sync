namespace :load do
  task :defaults do
    set :db_sync_dumps_path,                -> { "#{shared_path}/db_dumps" }
    set :db_sync_download_path,             -> { './tmp' }
    set :db_sync_staging_before_sync_tasks, -> { 'puma:stop' }
    set :db_sync_staging_after_sunc_tasks,  -> { 'puma:start' }
  end
end

namespace :db do
  desc 'Create and download a dump of production database'
  task :download_production_dump do
    on roles(:db) do |host|
      execute "touch #{dump_file}"
      execute "chmod go+rw #{dump_file}"

      db        = load_db_config :production
      db_name   = "postgresql://#{db['username']}:#{db['password']}@#{db['host']}:5432/#{db['database']}"
      dump_cmd  = "pg_dump --clean --no-owner --no-privileges --dbname=#{db_name} -f #{dump_file}"

      execute "sudo su - postgres -c 'touch #{dump_file}'"
      execute "sudo su - postgres -c '#{dump_cmd}'"
      execute "gzip #{dump_file}"
      download! compressed_dump_file, downloaded_compressed_file
      execute "rm -f #{compressed_dump_file}"
    end
    run_locally do
      with rails_env: :development do
        execute "gzip -df #{downloaded_compressed_file}"
      end
    end
  end

  desc 'Load a dump into a staging database'
  task :load_into_staging do
    db       = load_db_config :staging
    db_name  = "postgresql://#{db['username']}:#{db['password']}@#{db['host']}:5432/#{db['database']}"

    run_locally do
      # stop staging server
      if before_tasks = fetch(:db_sync_staging_before_sync_tasks)
        execute "cap staging #{before_tasks}"
      end
      # prepare database
      execute 'cap staging db:clear_staging_database'
      execute "psql --dbname=#{db_name} < #{local_backup_file}"
      # run db:migrate and clear cache
      execute 'cap staging deploy:migrating'
      # start staging server
      if after_tasks = fetch(:db_sync_staging_after_sunc_tasks)
        execute "cap staging #{after_tasks}"
      end
    end
  end

  task :clear_staging_database do
    db  = load_db_config :staging
    cmd = '$HOME/.rbenv/bin/rbenv exec bundle exec rails db:environment:set db:drop db:create'

    run_locally do
      execute "ssh #{fetch(:user)}@#{db['host']} 'cd #{deploy_to}/current; #{cmd}'"
    end
  end

  desc 'Load a dump into a localhost database'
  task :load_into_localhost do
    db        = load_db_config :development
    db_name   = "postgresql://#{db['username']}:#{db['password']}@#{db['host']}:5432/#{db['database']}"

    run_locally do
      execute 'bundle exec rails db:drop'
      execute 'bundle exec rails db:create'
      execute "psql --dbname=#{db_name} < #{local_backup_file}"
      # dump was set `ar_internal_metadata.environment` to `production` so we need to change it
      execute 'bundle exec rails db:environment:set'
      execute 'bundle exec rails db:migrate'
    end
  end

  desc 'Synchronize development database on a localhost'
  task :sync_dev do
    invoke 'db:download_production_dump'
    invoke 'db:load_into_localhost'
  end

  desc 'Synchronize database on a staging instance'
  task :sync_staging do
    invoke 'db:download_production_dump'
    invoke 'db:load_into_staging'
  end

  desc 'Synchronize database on a staging and a localhost'
  task :sync_all do
    invoke 'db:download_production_dump'
    invoke 'db:load_into_localhost'
    invoke 'db:load_into_staging'
  end

  def load_db_config(environment)
    YAML.load_file('config/database.yml')[environment.to_s]
  end

  def dump_file
    @dump_file ||= "#{fetch(:db_sync_dumps_path)}/dump-#{Time.now.utc.strftime('%Y-%m-%d-%H:%M:%S')}.sql"
  end

  def compressed_dump_file
    @compressed_dump_file ||= "#{dump_file}.gz"
  end

  def downloaded_compressed_file
    @downloaded_compressed_file ||= "#{local_backup_file}.gz"
  end

  def local_backup_file
    @local_backup_file ||= "#{fetch(:db_sync_download_path)}/backup-#{fetch(:stage)}.sql"
  end
end
