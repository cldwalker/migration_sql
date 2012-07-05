namespace :db do
  desc "Dumps sql for migrations into db/migration_sql using test database"
  task :dump_migration_sql do
    # We use the test environment since it should be easy for a user to recreate
    ENV['RAILS_ENV'] = 'test'
    Rails.env = 'test'

    MigrationSql.invoke_pre_dump_tasks
    MigrationSql.dump
  end
end
