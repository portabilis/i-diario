class ActiveSearchesSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code,
          ano: year
        )['busca_ativa']
      )
    )
  end

  private

  def api_class
    IeducarApi::ActiveSearches
  end

  def update_records(active_searches)
    active_searches.each do |active_search_record|
      student_enrollment = StudentEnrollment.find_by(api_code: active_search_record.ref_cod_matricula)

      ActiveSearch.find_or_initialize_by(student_enrollment_id: student_enrollment.id).tap do |active_search|
        active_search.start_date = active_search_record.data_inicio
        active_search.end_date = active_search_record.data_fim
        active_search.status = active_search_record.resultado_busca_ativa
        active_search.observations = active_search_record.observacoes

        active_search.save! if active_search.changed?
      end
    end
  end
end
