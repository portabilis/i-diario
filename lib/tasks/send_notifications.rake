namespace :send_notification do
  desc 'Send absence notification'
  task absences: :environment do
    Entity.active.each do |entity|
      Rails.logger.info "Enviando notificação para a entidade: #{entity.name} (ID: #{entity.id})"

      jid = InfrequencyTrackingNotifierWorker.perform_in(1.second, entity.id)

      if jid.present?
        Rails.logger.info "Notificação agendada com sucesso para #{entity.name} (ID: #{entity.id}) - Job ID: #{jid}"
      else
        Rails.logger.error "Falha ao agendar notificação para #{entity.name} (ID: #{entity.id})"
      end
    end
  end
end
