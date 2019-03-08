namespace :execute_sql do
  desc 'Execute select to return result'
  task :select, [:select] => :environment do |t, args|
    args.with_defaults(select: 'select * from users')

    Entity.active.each do |entity|
      entity.using_connection do
        ActiveRecord::Base.connection.select_rows(args[:select]).each do |item|
          puts entity.id.to_s + "-" + entity.name + ": " + item.join(' - ')
        end
      end
    end
  end

  desc 'Execute update to reset api synchronizer'
  task reset_api_synchronizer: :environment do
    puts "Iniciando o reset da api synchronizer"

    Entity.active.each do |entity|
      entity.using_connection do
        IeducarApiSynchronization.cancel_not_running_synchronizations(entity, restart: true)
      end
    end

    puts "Finalizado o reset da api synchronizer"
  end
end
