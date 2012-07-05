# -*- encoding: utf-8 -*-
require File.expand_path('../lib/migration_sql/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Gabriel Horner"]
  gem.email         = ["gabriel.horner@gmail.com"]
  gem.description   = "Generates the sql equivalent of db/migrate into db/migration_sql. Currently only works for Rails apps and Sequel."
  gem.summary       = %q{Dumps migration sql into db/migration_sql}
  gem.homepage      = "http://github.com/cldwalker/migration_sql"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "migration_sql"
  gem.version       = MigrationSql::VERSION
end
