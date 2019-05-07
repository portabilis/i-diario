class SynchronizerBuilderWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, retry: 3, dead: false

  sidekiq_retries_exhausted do |msg, exception|
    params = msg['args']

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      synchronization.mark_as_error!(
        I18n.t('ieducar_api.error.messages.sync_error'),
        exception.message
      )
    end
  end

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
          call_worker(params, synchronization)
        end
      end
    end
  end

  private

  def call_worker(params, synchronization)
    worker_state = nil
    worker_batch = WorkerBatch.find(params[:worker_batch_id])
    orchestrator = SynchronizationOrchestrator.new(worker_batch, params[:klass], params)

    WorkerState.first.with_lock do
      return unless orchestrator.can_synchronize?

      worker_state = create_worker_state(
        params.slice(
          :klass,
          :year,
          :unity_api_code,
          :filtered_by_year,
          :filtered_by_unity
        ).merge(
          worker_batch: worker_batch
        )
      )
    end

    SynchronizerExecuterWorker.perform_async(
      params.slice(
        :klass,
        :synchronization_id,
        :worker_batch_id,
        :entity_id,
        :year,
        :years,
        :unity_api_code,
        :unities_api_code,
        :filtered_by_year,
        :filtered_by_unity
      ).merge(
        worker_state_id: worker_state.id
      )
    )
  rescue Sidekiq::Shutdown => error
    raise error
  rescue StandardError => error
    if error.message != '502 Bad Gateway'
      synchronization.mark_as_error!(I18n.t('ieducar_api.error.messages.sync_error'), error.message)
    end

    raise error
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
end
