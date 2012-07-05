require 'rails/railtie'

module MigrationSql
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/migration_sql.rake"
    end
  end
end
