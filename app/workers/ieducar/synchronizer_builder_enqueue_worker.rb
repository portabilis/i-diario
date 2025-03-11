class SynchronizerBuilderEnqueueWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :synchronizer_enqueue_next_job

  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
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
