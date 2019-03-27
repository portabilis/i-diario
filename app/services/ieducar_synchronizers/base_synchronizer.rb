class BaseSynchronizer
  class << self
    def synchronize_in_batch!(synchronization, worker_batch, years = nil, unity_api_code = nil, entity_id = nil)
      worker_state = create_worker_state(worker_batch)

      if block_given?
        yield
      else
        new(synchronization, worker_batch, years, unity_api_code, entity_id).synchronize!
      end

      worker_batch.increment(worker_name)

      finish_worker(worker_state, worker_batch, synchronization)
    end

    private

    def create_worker_state(worker_batch)
      worker_state = WorkerState.create!(
        worker_batch: worker_batch,
        kind: worker_name
      )
      worker_state.start!
      worker_state
    end

    def finish_worker(worker_state, worker_batch, synchronization)
      worker_state.end!

      synchronization.mark_as_completed! if worker_batch.all_workers_finished?
    end

    def worker_name
      self.class.to_s
    end
  end

  def initialize(synchronization, worker_batch, years, unity_api_code, entity_id)
    self.synchronization = synchronization
    self.worker_batch = worker_batch
    self.years = Array(years).compact
    self.unity_api_code = unity_api_code
    self.entity_id = entity_id

    worker_batch.touch
  end

  protected

  attr_accessor :synchronization, :worker_batch, :years, :unity_api_code, :entity_id, :worker_state

  def api
    @api = api_class.new(synchronization.to_api, synchronization.full_synchronization)
  end

  def api_class
    IeducarApi::Base
  end
end
