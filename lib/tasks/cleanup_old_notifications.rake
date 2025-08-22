namespace :notifications do
  desc 'Remove notificações do sistema com mais de 18 meses para todas as entidades'
  task cleanup_old: :environment do
    # Limpa notificações com mais de 18 meses, mantendo histórico relevante
    # mas removendo dados desnecessários que impactam a performance.
    #
    # Esta task deve ser executada mensalmente via cron job.
    cutoff_date = 18.months.ago
    total_deleted = 0

    puts "Iniciando limpeza de notificações do sistema anteriores a #{cutoff_date.strftime('%d/%m/%Y')}"
    Rails.logger.info "Iniciando limpeza de notificações do sistema - data de corte: #{cutoff_date}"

    # Itera sobre todas as entidades
    Entity.all.each do |entity|
      entity.using_connection do
        begin
          puts "\nProcessando entidade: #{entity.name} (ID: #{entity.id})"

          # Conta notificações que serão removidas
          old_notifications_count = SystemNotification.where('created_at < ?', cutoff_date).count

          if old_notifications_count > 0
            puts "  Encontradas #{old_notifications_count} notificações para remover"

            # Usa transação para garantir atomicidade
            ActiveRecord::Base.transaction do
              # Remove primeiro os targets (registros de leitura por usuário)
              # usando join para evitar carregar todas as notificações em memória
              entity_targets_deleted = SystemNotificationTarget
                .joins(:system_notification)
                .where('system_notifications.created_at < ?', cutoff_date)
                .delete_all

              # Remove as notificações
              entity_deleted_count = SystemNotification.where('created_at < ?', cutoff_date).delete_all

              total_deleted += entity_deleted_count
              puts "  Total removido: #{entity_deleted_count} notificações e #{entity_targets_deleted} targets"
              Rails.logger.info "Entidade #{entity.name} (ID: #{entity.id}): removidas #{entity_deleted_count} notificações antigas e #{entity_targets_deleted} targets"
            end
          else
            puts "  Nenhuma notificação com mais de 18 meses encontrada"
          end
        rescue => e
          puts "  ERRO ao processar entidade #{entity.name}: #{e.message}"
          Rails.logger.error "Erro ao limpar notificações da entidade #{entity.name} (ID: #{entity.id}): #{e.message}"
          Rails.logger.error e.backtrace.join("\n")
        end
      end
    end

    puts "\nLimpeza concluída. Total de notificações removidas: #{total_deleted}"
    Rails.logger.info "Limpeza de notificações do sistema concluída. Total removido: #{total_deleted}"
  end
end