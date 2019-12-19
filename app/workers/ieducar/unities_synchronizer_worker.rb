class UnitiesSynchronizerWorker < BaseSynchronizerWorker
  def perform(entity_id, synchronization_id, last_two_years)
    Entity.find(entity_id).using_connection do
      synchronization = IeducarApiSynchronization.started.find_by(id: synchronization_id)
      worker_batch = synchronization.worker_batch
      worker_batch.start!

      worker_state = WorkerState.create!(
        worker_batch: worker_batch,
        kind: UnitiesSynchronizer.to_s
      )

      params = {
        entity_id: entity_id,
        worker_state_id: worker_state.id,
        year: [],
        unity_api_code: [],
        filtered_by_year: false,
        filtered_by_unity: false,
        synchronization_id: synchronization.id,
        worker_batch_id: worker_batch.id,
        last_two_years: last_two_years
      }

      UnitiesSynchronizer.synchronize!(params)
    end
  end
end
