class SynchronizerExecuterEnqueueWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  queue: :synchronizer_enqueue_next_job,
                  on_conflict: { client: :log, server: :reject },
                  retry: 3,
                  dead: false

  sidekiq_retries_exhausted do |msg, exception|
    params = msg['args'].first.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      synchronization.mark_as_error!(
        I18n.t('ieducar_api.error.messages.sync_error'),
        "Erro no enqueue do executer: #{exception.message}"
      )
    end

    Honeybadger.notify(
      exception,
      context: {
        worker_class: 'SynchronizerExecuterEnqueueWorker',
        params: params,
        synchronization_id: params[:synchronization_id],
        entity_id: params[:entity_id],
        klass: params[:klass]
      }
    )
  end

  def perform(params)
    params = params.with_indifferent_access
    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      return unless synchronization.started?

      enqueue_job(params, synchronization)
    end
  end

  private

  def enqueue_job(params, synchronization)
    worker_batch = WorkerBatch.find(params[:worker_batch_id])
    orchestrator = SynchronizationOrchestrator.new(worker_batch, params[:klass], params)

    return unless orchestrator.can_synchronize?

    worker_state = create_worker_state(worker_state_params(params, worker_batch))

    SynchronizerExecuterWorker.set(
      queue: synchronization.full_synchronization? ? :synchronizer_full : :synchronizer
    ).perform_async(synchronizer_executer_params(params, worker_state.id))
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
      :filtered_by_unity,
      :current_years
    ).merge(
      worker_state_id: worker_state_id
    )
  end
end
