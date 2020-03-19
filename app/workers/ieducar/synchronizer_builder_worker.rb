class SynchronizerBuilderWorker < BaseSynchronizerWorker
  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      years = params[:years] if params[:filtered_by_year]
      years ||= [params[:years].join(',')]
      by_unity = params[:filtered_by_unity] &&
                 (synchronization.full_synchronization || params[:klass] == SchoolCalendarsSynchronizer.to_s)
      unities = params[:unities_api_code] if by_unity
      unities ||= [params[:unities_api_code].join(',')]

      years.each do |year|
        unities.each do |unity_api_code|
          params[:year] = year
          params[:unity_api_code] = unity_api_code

          SynchronizerExecuterEnqueueWorker.perform_in(
            1.second,
            params
          )
        end
      end
    end
  end
end
