require 'fileutils'
require 'migration_sql/version'
require 'migration_sql/railtie' if defined?(Rails)
require 'migration_sql/sequel'

module MigrationSql
  class << self
    # Current migration in db/migrate which is being run
    attr_accessor :current_migration_name
    # boolean which indicates whether executed sql should be logged
    attr_accessor :loggable
    # Array of rake task names used to create an app's database(s).
    # Default is just db:create
    attr_accessor :db_create_tasks
  end
  self.db_create_tasks = %w{db:create}

  # Runs migrations in db/migrate and dumps their sql into db/migration_sql.
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

  # Appends sql to current migration file.
  def self.log(sql)
    File.open(current_migration_file, 'a') { |file| file << sql << ";\n" }
  end

  # Runs rake tasks required before calling dump.
  def self.invoke_pre_dump_tasks
    (%w{environment db:drop} + db_create_tasks).each do |task|
      Rake::Task[task].invoke
    end
  end

  private

  def self.output_dir
    @output_dir ||= Rails.root.join('db', 'migration_sql').tap do |dir|
      FileUtils.mkdir_p dir
    end
  end

  def self.current_migration_file
    output_dir.join(current_migration_name).to_s.sub(/\.rb$/, '.sql')
  end

  def self.log_sql
    self.loggable = true
    yield
    self.loggable = nil
  end

  def self.insert_schema_migration
    log %[INSERT INTO `schema_migrations` (`filename`) VALUES ('#{current_migration_name}')]
  end
end
