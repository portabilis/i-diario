class StudentEnrollmentDependenceSynchronizerWorker
  include Sidekiq::Worker
  include EntityWorker

  def perform_in_entity(synchronization_id, worker_batch_id, years)
    synchronization = IeducarApiSynchronization.find(synchronization_id)
    worker_batch = WorkerBatch.find(worker_batch_id)

    begin
      StudentEnrollmentDependenceSynchronizer.synchronize!(synchronization, worker_batch, years)
    rescue IeducarApi::Base::ApiError => e
      synchronization.mark_as_error!(e.message)
    rescue Exception => exception
      synchronization.mark_as_error!('Ocorreu um erro desconhecido.')

      raise exception
    end
  end
end
