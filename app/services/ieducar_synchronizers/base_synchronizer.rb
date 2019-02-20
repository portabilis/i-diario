class BaseSynchronizer
  class << self
    def synchronize!(synchronization, worker_batch, years = nil, unity_api_code = nil, entity_id = nil)
      new(synchronization, worker_batch, years, unity_api_code, entity_id).synchronize!
    end
    alias_method 'synchronize_in_batch!', 'synchronize!'
  end

  def initialize(synchronization, worker_batch, years, unity_api_code, entity_id)
    self.synchronization = synchronization
    self.worker_batch = worker_batch
    self.years = Array(years).compact
    self.unity_api_code = unity_api_code
    self.entity_id = entity_id

    create_worker_state
  end

  protected

  attr_accessor :synchronization, :worker_batch, :years, :unity_api_code, :entity_id, :worker_state

  def create_worker_state
    self.worker_state = WorkerState.create!(
      worker_batch: worker_batch,
      kind: worker_name
    )
    worker_state.start!
  end

  def finish_worker
    worker_state.end!

    worker_batch.with_lock do
      worker_batch.done_workers = (worker_batch.done_workers + 1)
      worker_batch.completed_workers = (worker_batch.completed_workers << worker_name) if Rails.logger.debug?
      worker_batch.save!

      if worker_batch.all_workers_finished?
        worker_batch.end!
        synchronization.mark_as_completed!
      end
    end
  end

  def worker_name
    self.class.to_s
  end
end
