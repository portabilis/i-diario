class WorkerBatch < ApplicationRecord
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

  def increment
    with_lock do
      self.done_workers = (done_workers + 1)
      save!

      yield if block_given? && all_workers_finished?
    end
  end

  def mark_as_error!
    update(status: ApiSynchronizationStatus::ERROR)
  end

  private

  def reset
    self.total_workers = 0
    self.done_workers = 0
    worker_states.delete_all
  end
end
