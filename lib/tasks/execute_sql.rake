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

        command = <<-SQL
          UPDATE ieducar_api_synchronizations
             SET status = 'error',
                 error_message = 'Erro desconhecido, tente novamente.',
                 notified = FALSE,
                 updated_at = now()
           WHERE status = 'started'
             AND created_at <= NOW() - '1 day'::INTERVAL;
        SQL

        if ActiveRecord::Base.connection.execute(command)
          puts msg + "Executado com sucesso!"
        else
          puts msg + "Erro ao executar!"
        end
      end
    end

    puts "Finalizado o reset da api synchronizer"
  end
end
