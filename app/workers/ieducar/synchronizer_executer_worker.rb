class SynchronizerExecuterWorker < BaseSynchronizerWorker
  def perform(params)
    params = params.with_indifferent_access

    Entity.find(params[:entity_id]).using_connection do
      synchronization = IeducarApiSynchronization.find(params[:synchronization_id])
      worker_batch = WorkerBatch.find(params[:worker_batch_id])

      params[:klass].constantize.synchronize!(
        synchronizer_params(params, synchronization, worker_batch)
      )
    end
  end

  private

  def synchronizer_params(params, synchronization, worker_batch)
    params.slice(
      :entity_id,
      :worker_state_id,
      :year,
      :unity_api_code,
      :filtered_by_year,
      :filtered_by_unity,
      :current_years
    ).merge(
      synchronization: synchronization,
      worker_batch: worker_batch
    )
  end
end
