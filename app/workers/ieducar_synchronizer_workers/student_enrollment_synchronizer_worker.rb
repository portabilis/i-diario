class StudentEnrollmentSynchronizerWorker
  include Sidekiq::Worker
  include EntityWorker

  def perform_in_entity(synchronization_id, worker_batch_id, years, unity_api_code)
    synchronization = IeducarApiSynchronization.find(synchronization_id)
    worker_batch = WorkerBatch.find(worker_batch_id)

    begin
      StudentEnrollmentSynchronizer.synchronize!(synchronization, worker_batch, years, unity_api_code)
    rescue IeducarApi::Base::ApiError => e
      synchronization.mark_as_error!(e.message)
    rescue Exception => exception
      synchronization.mark_as_error!('Ocorreu um erro desconhecido.')

      raise exception
    end
  end
end
