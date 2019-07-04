class DeficienciesSynchronizerWorker
  include Sidekiq::Worker
  include EntityWorker

  def perform_in_entity(synchronization_id, worker_batch_id)
    synchronization = IeducarApiSynchronization.find(synchronization_id)
    worker_batch = WorkerBatch.find(worker_batch_id)

    begin
      DeficienciesSynchronizer.synchronize!(synchronization, worker_batch)
    rescue IeducarApi::Base::ApiError => e
      synchronization.mark_as_error!(e.message)
    rescue Exception => exception
      synchronization.mark_as_error!('Ocorreu um erro desconhecido.')

      raise exception
    end
  end
end
