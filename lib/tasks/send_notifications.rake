namespace :send_notification do
  desc 'Send absence notification'
  task absences: :environment do
    Entity.active.each do |entity|
      InfrequencyTrackingNotifierWorker.perform_in(1.second, entity.id)

      puts "Notificação de infrequencia foi disparada com sucesso para a entidade #{entity.name}"
      puts 'Para mais detalhes acompanhe a execução do worker InfrequencyTrackingNotifierWorker no sidekiq'
    end
  end
end
