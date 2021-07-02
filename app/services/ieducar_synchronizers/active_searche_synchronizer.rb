class ActiveSearcheSynchronizer < BaseSynchronizer
  def create_or_update_active_search(student_enrollment)
    ActiveSearch.find_or_initialize_by(student_enrollment_id: student_enrollment.id).tap do |active_search|
      active_search.start_date = active_search_record.data_inicio
      active_search.end_date = active_search_record.data_fim
      active_search.status = active_search_record.resultado_busca_ativa
      active_search.observations = active_search_record.observacoes

      active_search.save! if active_search.changed?
    end
  end
end
