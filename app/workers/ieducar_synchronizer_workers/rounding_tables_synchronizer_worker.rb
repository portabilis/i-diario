class RoundingTablesSynchronizerWorker
  include Sidekiq::Worker

  def perform(entity_id, synchronization_id, worker_batch_id)
    Entity.find(entity_id).using_connection do
      synchronization = IeducarApiSynchronization.find(synchronization_id)
      worker_batch = WorkerBatch.find(worker_batch_id)

      begin
        RoundingTablesSynchronizer.synchronize!(synchronization, worker_batch)
      rescue IeducarApi::Base::ApiError => e
        synchronization.mark_as_error!(e.message)
      rescue Exception => exception
        synchronization.mark_as_error!('Ocorreu um erro desconhecido.')

        raise exception
      end
    end
  end
end
