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
      ActiveSearcheSynchronizer.student_enrollment_by_active_search(active_search_record)
    end
  end
end
