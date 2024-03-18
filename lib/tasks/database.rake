namespace :db do
  desc "Migrate the databases"
  task migrate_dbs: :environment do

    # Ajusta ActiveRecord::Migrations.migrations_paths pois ele simplesmente chumba o path db/migrate e ignora as configurações da aplicação
    ActiveRecord::Migrator.migrations_paths = Educacao::Application.config.paths['db/migrate'].expanded

    ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
    ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, ENV["VERSION"] ? ENV["VERSION"].to_i : nil) do |migration|
      ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
    end

    Entity.find_each(batch_size: 100) do |entity|
      entity.using_connection do
        puts "Migrating db: #{entity.domain}"

        ActiveRecord::Migration.verbose = ENV["VERBOSE"] ? ENV["VERBOSE"] == "true" : true
        ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, ENV["VERSION"] ? ENV["VERSION"].to_i : nil) do |migration|
          ENV["SCOPE"].blank? || (ENV["SCOPE"] == migration.scope)
        end
      end
    end
  end

  namespace :migrate do
    task :down_dbs => [:environment, :load_config] do
      raise "VERSION is required - To go down one migration, use db:rollback" if ENV["VERSION"] && ENV["VERSION"].empty?
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil

      ActiveRecord::Migrator.run(:down, ActiveRecord::Migrator.migrations_paths, version)

      Entity.find_each(batch_size: 100) do |entity|
        entity.using_connection do
          puts "Migrating db: #{entity.domain}"

          ActiveRecord::Migrator.run(:down, ActiveRecord::Migrator.migrations_paths, version)
        end
      end
    end

    task run_specific_tenant: :environment do
      begin
        Entity.find_by_name(ENV["TENANT"].to_sym).using_connection do
          ActiveRecord::Migrator.migrations_paths = Educacao::Application.config.paths['db/migrate'].expanded
          ActiveRecord::Migration.verbose = true

          puts "Migrating db: #{Entity.current.domain}"

          ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
        end
      rescue Exception => e
        puts "Database #{ENV["TENANT"]} not found"
      end
    end
  end
end

task('db:migrate').clear.enhance ['db:migrate_dbs']
task('db:migrate:down').clear.enhance ['db:migrate:down_dbs']
