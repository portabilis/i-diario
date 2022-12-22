class ActiveSearchSynchronizer
  include Sidekiq::Worker

  def perform(api_code, student_enrollment_id, active_search_record)
    ActiveSearch.find_or_initialize_by(api_code: api_code).tap do |active_search|
      active_search.student_enrollment_id = student_enrollment_id
      active_search.start_date = active_search_record.data_inicio
      active_search.end_date = active_search_record.data_fim
      active_search.status = active_search_record.resultado_busca_ativa
      active_search.observations = active_search_record.observacoes

      active_search.save! if active_search.changed?

      active_search.discard_or_undiscard(active_search_record.deleted_at.present?)

      ActiveSearchService.new(active_search).daily_note
    end
  end
end
