class UnitiesSynchronizer
  def self.synchronize!(params)
    synchronization = IeducarApiSynchronization.started.find_by(id: params[:synchronization_id])
    api = IeducarApi::Schools.new(synchronization.to_api, synchronization.full_synchronization)

    new(params).update_schools(
      HashDecorator.new(
        api.fetch_all['escolas']
      )
    )
  end

  def initialize(params)
    self.synchronization_id = params[:synchronization_id]
    self.worker_batch_id = params[:worker_batch_id]
    self.worker_state_id = params[:worker_state_id]
    self.entity_id = params[:entity_id]
    self.last_two_years = params[:last_two_years]
  end

  attr_accessor :synchronization_id, :worker_batch_id, :worker_state_id, :entity_id, :last_two_years

  def update_schools(schools)
    worker_batch = WorkerBatch.find(worker_batch_id)
    worker_state = WorkerState.find(worker_state_id)
    worker_state.start!

    sleep(5.second)

    worker_batch.increment
    worker_state.end!

    unities_api_code = Unity.with_api_code.pluck(:api_code)

    SynchronizerBuilderWorker.perform_async(
      klass: SchoolCalendarsSynchronizer.to_s,
      synchronization_id: synchronization_id,
      worker_batch_id: worker_batch_id,
      entity_id: entity_id,
      years: [],
      unities_api_code: unities_api_code,
      filtered_by_year: false,
      filtered_by_unity: true,
      last_two_years: last_two_years
    )
  rescue StandardError => error
    worker_state.mark_with_error!(error.message) if error.message != '502 Bad Gateway'

    raise error
  end
end
