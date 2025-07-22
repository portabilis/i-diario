class SynchronizerBuilderEnqueueWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  queue: :synchronizer_enqueue_next_job,
                  on_conflict: { client: :log, server: :reject },
                  retry: 3,
                  dead: false

  sidekiq_retries_exhausted do |msg, exception|
    params = msg['args'].first.with_indifferent_access

    synchronization = nil
    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find_by(id: params[:synchronization_id])

      synchronization&.mark_as_error!(
        I18n.t('ieducar_api.error.messages.sync_error'),
        "Erro no enqueue do builder: #{exception.message}"
      )
    end

    Honeybadger.notify(
      exception,
      context: {
        worker_class: 'SynchronizerBuilderEnqueueWorker',
        params: params,
        synchronization_id: params[:synchronization_id],
        entity_id: params[:entity_id],
        synchronization_exists: synchronization.present?
      }
    )
  end

  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find_by(id: params[:synchronization_id])

      return unless synchronization
      return unless synchronization.started?

      worker_batch = WorkerBatch.find(params[:worker_batch_id])

      SynchronizationOrchestrator.new(
        worker_batch,
        params[:klass],
        synchronization_orchestrator_params(params, synchronization)
      ).enqueue_next
    end
  end

  private

  def synchronization_orchestrator_params(params, synchronization)
    params.slice(
      :entity_id,
      :year,
      :unity_api_code,
      :current_years
    ).merge(
      synchronization: synchronization
    )
  end
end
