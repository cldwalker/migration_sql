namespace :db do
  desc "Dumps sql for migrations into db/migration_sql using test database"
  task :dump_migrations do
    ENV['RAILS_ENV'] = 'test'
    Rails.env = 'test'
    MigrationSql.invoke_pre_dump_tasks
    MigrationSql.dump
  end
end
