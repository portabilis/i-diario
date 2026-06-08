# frozen_string_literal: true

namespace :discipline_records do
  desc 'Remove registros de exclusao em lote do ano anterior para todas as entidades'
  task cleanup_old_deletions: :environment do
    # Limpa registros de discipline_record_deletions e seus postings do ano anterior
    # com pelo menos 4 meses de criacao.
    # Ex: rake executada em 17/03/2026, remove registros com year <= 2025 e created_at < 17/11/2025.

    previous_year = Date.current.year - 1
    cutoff_date = 4.months.ago
    total_deleted = 0

    puts "Iniciando limpeza de registros de exclusao do ano #{previous_year} criados antes de #{cutoff_date.strftime('%d/%m/%Y')}"
    Rails.logger.info "Iniciando limpeza de discipline_record_deletions - ano: #{previous_year}, criados antes de: #{cutoff_date}"

    Entity.all.each do |entity|
      entity.using_connection do
        puts "\nProcessando entidade: #{entity.name} (ID: #{entity.id})"

        old_deletions = DisciplineRecordDeletion
                        .where("(filters->>'year')::int <= ?", previous_year)
                        .where('created_at < ?', cutoff_date)
        old_count = old_deletions.count

        if old_count.positive?
          puts "  Encontrados #{old_count} registros para remover"

          ActiveRecord::Base.transaction do
            postings_deleted = DisciplineRecordDeletionPosting
                               .where(discipline_record_deletion_id: old_deletions.select(:id))
                               .delete_all

            deletions_deleted = old_deletions.delete_all

            total_deleted += deletions_deleted
            puts "  Removidos: #{deletions_deleted} deletions e #{postings_deleted} postings"
            Rails.logger.info(
              "Entidade #{entity.name} (ID: #{entity.id}): " \
              "removidos #{deletions_deleted} deletions e #{postings_deleted} postings"
            )
          end
        else
          puts "  Nenhum registro elegivel para remoção"
        end
      rescue StandardError => e
        puts "  ERRO ao processar entidade #{entity.name}: #{e.message}"
        Rails.logger.error "Erro na limpeza de deletions da entidade #{entity.name} (ID: #{entity.id}): #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    puts "\nLimpeza concluida. Total de registros removidos: #{total_deleted}"
    Rails.logger.info "Limpeza de discipline_record_deletions concluida. Total removido: #{total_deleted}"
  end
end
