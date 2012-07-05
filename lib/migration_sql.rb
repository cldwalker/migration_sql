require 'fileutils'
require 'migration_sql/version'
require 'migration_sql/railtie' if defined?(Rails)
require 'migration_sql/sequel'

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
    MigrationSql::Sequel.hook_into_classes

    previous_target = nil
    Dir['db/migrate/*.rb'].sort.each do |file|
      self.current_migration_name = File.basename(file)
      target = file[/\d+/].to_i
      MigrationSql::Sequel.run_migration previous_target, target
      previous_target = target
    end
  end

  # Takes a block which should run actual migration. Any args passed to this
  # method are passed on to the block.
  def self.apply_migration(*args)
    if File.exists? current_migration_file
      yield(*args)
    else
      log_sql { yield(*args) }
      insert_schema_migration
      puts "Saved sql for #{current_migration_name}"
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

  def self.invoke_pre_dump_tasks
    (%w{environment db:drop} + db_create_tasks).each do |task|
      Rake::Task[task].invoke
    end
  end
end
