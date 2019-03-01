class WorkerBatch < ActiveRecord::Base
  include LifeCycleTimeLoggable

  belongs_to :stateable, polymorphic: true
  has_many :worker_states, dependent: :restrict_with_error

  def all_workers_finished?
    with_lock do
      total_workers == done_workers
    end
  end

  def done_percentage
    return 0 if total_workers.zero?

    ((done_workers.to_f / total_workers.to_f) * 100).round(0)
  end

  def self.increment(worker_batch_id, done_info)
    worker_batch = WorkerBatch.find(worker_batch_id)
    worker_batch.increment(done_info) do
      yield if block_given?
    end
  end

  def increment(done_info)
    with_lock do
      self.done_workers = (done_workers + 1)
      self.completed_workers = (completed_workers << done_info) if Rails.logger.debug?
      save!

      yield if block_given? && all_workers_finished?
    end
  end

  private

  def reset
    self.total_workers = 0
    self.done_workers = 0
    self.completed_workers = []
  end
end
