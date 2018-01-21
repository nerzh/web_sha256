require 'active_record'
require 'yaml'

namespace :db do
  desc "Migrate the database"
  task :migrate do
    ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil )
  end
end

dbconfig = YAML::load(File.open(File.join(File.dirname(__FILE__), 'config', 'database.yml')))

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.establish_connection(dbconfig['development'])