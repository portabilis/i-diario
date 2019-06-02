class SynchronizerBuilderWorker < BaseSynchronizerWorker
  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      years = params[:years] if params[:filtered_by_year]
      years ||= [params[:years].join(',')]
      unities = params[:unities_api_code] if params[:filtered_by_unity] && synchronization.full_synchronization
      unities ||= [params[:unities_api_code].join(',')]

      years.each do |year|
        unities.each do |unity_api_code|
          params[:year] = year
          params[:unity_api_code] = unity_api_code
          enqueue_job(params)
        end
      end
    end
  end

  private

  def enqueue_job(params)
    worker_state = nil
    worker_batch = WorkerBatch.find(params[:worker_batch_id])
    orchestrator = SynchronizationOrchestrator.new(worker_batch, params[:klass], params)

    worker_state_locked_by_worker_batch(worker_batch) do
      return unless orchestrator.can_synchronize?

      worker_state = create_worker_state(worker_state_params(params, worker_batch))
    end

    SynchronizerExecuterWorker.perform_async(synchronizer_executer_params(params, worker_state.id))
  end

  def worker_state_locked_by_worker_batch(worker_batch)
    worker_batch.with_lock do
      worker_batch.touch

      yield
    end
  end

  def create_worker_state(params)
    worker_state = WorkerState.create!(
      worker_batch: params[:worker_batch],
      kind: params[:klass]
    )

    if params[:filtered_by_year] || params[:filtered_by_unity]
      meta_data = {}
      meta_data[:year] = params[:year].to_s if params[:filtered_by_year]
      meta_data[:unity_api_code] = params[:unity_api_code] if params[:filtered_by_unity]
      worker_state.update(meta_data: meta_data)
    end

    worker_state.enqueued!
    worker_state
  end

  def worker_state_params(params, worker_batch)
    params.slice(
      :klass,
      :year,
      :unity_api_code,
      :filtered_by_year,
      :filtered_by_unity
    ).merge(
      worker_batch: worker_batch
    )
  end

  def synchronizer_executer_params(params, worker_state_id)
    params.slice(
      :klass,
      :synchronization_id,
      :worker_batch_id,
      :entity_id,
      :year,
      :unity_api_code,
      :filtered_by_year,
      :filtered_by_unity
    ).merge(
      worker_state_id: worker_state_id
    )
  end
end
