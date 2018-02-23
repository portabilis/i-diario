namespace :execute_sql do
  desc 'Execute select to return result'
  task :select, [:select] => :environment do |t, args|
    args.with_defaults(select: 'select * from users')

    Entity.all.each do |entity|
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

    Entity.all.each do |entity|
      entity.using_connection do
        msg = entity.id.to_s + "-" + entity.name + ": "

        if ActiveRecord::Base.connection.execute("UPDATE ieducar_api_synchronizations SET status = 'completed' WHERE status = 'started';")
          puts msg + "Executado com sucesso!"
        else
          puts msg + "Erro ao executar!"
        end
      end
    end

    puts "Finalizado o reset da api synchronizer"
  end
end
