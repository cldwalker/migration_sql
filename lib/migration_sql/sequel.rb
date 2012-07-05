require 'sequel/extensions/migration'

module MigrationSql
  module Sequel
    def self.run_migration(current_migration, next_migration)
      ::Sequel::Migrator.run(::Sequel::Model.db, "db/migrate", :target => next_migration,
                             :current => current_migration)
    end

    def self.hook_into_classes
      ::Sequel::Model.db.extend DatabaseLogger

      ::Sequel::Migration.class_eval do
        class << self
          alias_method :old_apply, :apply

          def apply(db, direction)
            MigrationSql.apply_migration(db, direction) do
              old_apply(db, direction)
            end
          end
        end
      end
    end

    module DatabaseLogger
      def execute(sql, opts = {})
        MigrationSql.log(sql) if MigrationSql.loggable
        super
      end
    end
  end
end
