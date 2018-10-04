class BaseSynchronizer
  def self.synchronize!(synchronization, worker_batch, years = nil, unity_api_code = nil, entity_id = nil)
    new(synchronization, worker_batch, years, unity_api_code, entity_id).synchronize!
  end

  def initialize(synchronization, worker_batch, years, unity_api_code, entity_id)
    self.synchronization = synchronization
    self.worker_batch = worker_batch
    self.years = years
    self.unity_api_code = unity_api_code
    self.entity_id = entity_id
  end

  protected

  attr_accessor :synchronization, :worker_batch, :years, :unity_api_code, :entity_id

  def finish_worker(synchronizer)
    worker_batch.with_lock do
      worker_batch.done_workers = (worker_batch.done_workers + 1)
      if Rails.logger.debug?
        worker_batch.completed_workers = (worker_batch.completed_workers << synchronizer)
      end
      worker_batch.save!

      if worker_batch.all_workers_finished?
        synchronization.mark_as_completed!
      end
    end
  end
end
