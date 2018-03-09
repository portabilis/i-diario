class BaseSynchronizer
  def self.synchronize!(synchronization, worker_batch, years = nil, unity_api_code = nil)
    new(synchronization, worker_batch, years, unity_api_code).synchronize!
  end

  def initialize(synchronization, worker_batch, years, unity_api_code)
    self.synchronization = synchronization
    self.worker_batch = worker_batch
    self.years = years
    self.unity_api_code = unity_api_code
  end

  protected

  attr_accessor :synchronization, :worker_batch, :years, :unity_api_code

  def finish_worker(synchronizer)
    worker_batch.with_lock do
      worker_batch.done_worker!(synchronizer)

      if worker_batch.all_workers_finished?
        synchronization.mark_as_completed!
      end
    end
  end
end
