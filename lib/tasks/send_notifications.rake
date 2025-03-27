namespace :send_notification do
  desc 'Send absence notification'
  task absences: :environment do
    Entity.active.each do |entity|
      entity.using_connection do
        general_configuration = GeneralConfiguration.current

        next unless general_configuration.notify_consecutive_or_alternate_absences

        result = InfrequencyTrackingNotifierWorker.perform_in(1.second, entity.id)

        if result
          puts "Notificação de infrequencia foi disparada com sucesso para a entidade #{entity.name}"
          puts "Para mais detalhes acompanhe a execução do worker InfrequencyTrackingNotifierWorker no sidekiq"
        end
      end
    end
  end
end
