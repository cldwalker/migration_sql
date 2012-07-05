require 'sequel/extensions/migration'
require 'fileutils'
require 'migration_sql/version'
require 'migration_sql/railtie' if defined?(Rails)

module MigrationSql
  class << self; attr_accessor :current_migration_name, :loggable, :db_create_tasks; end
  self.db_create_tasks = %w{db:create}

  def self.output_dir
    @output_dir ||= Rails.root.join('db', 'migration_sql').tap do |dir|
      FileUtils.mkdir_p dir
    end
  end

  def self.current_migration_file
    output_dir.join(current_migration_name).to_s.sub(/\.rb$/, '.sql')
  end

  def self.dump
    hook_into_sequel_classes

    previous_target = nil
    Dir['db/migrate/*.rb'].sort.each do |file|
      self.current_migration_name = File.basename(file)
      target = file[/\d+/].to_i
      Sequel::Migrator.run(Sequel::Model.db, "db/migrate", :target => target, :current => previous_target)
      previous_target = target
    end
  end

  def self.hook_into_sequel_classes
    Sequel::Model.db.extend DatabaseLogger

    Sequel::Migration.class_eval do
      class << self
        alias_method :old_apply, :apply

        def apply(db, direction)
          if File.exists? MigrationSql.current_migration_file
            old_apply(db, direction)
          else
            MigrationSql.log_sql { old_apply(db, direction) }
            MigrationSql.insert_schema_migration
            puts "Saved sql for #{MigrationSql.current_migration_name}"
          end
        end
      end
    end
  end

  def self.log_sql
    self.loggable = true
    yield
    self.loggable = nil
  end

  def self.insert_schema_migration
    log %[INSERT INTO `schema_migrations` (`filename`) VALUES ('#{current_migration_name}')]
  end

  def self.log(sql)
    File.open(current_migration_file, 'a') { |file| file << sql << ";\n" }
  end

  module DatabaseLogger
    def execute(sql, opts = {})
      MigrationSql.log(sql) if MigrationSql.loggable
      super
    end
  end

  def self.invoke_pre_dump_tasks
    p db_create_tasks
    (%w{environment db:drop} + db_create_tasks).each do |task|
      Rake::Task[task].invoke
    end
  end
end
