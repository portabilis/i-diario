class WorkerBatch < ApplicationRecord
  include LifeCycleTimeLoggable

  belongs_to :stateable, polymorphic: true
  has_many :worker_states, dependent: :restrict_with_error

  scope :by_ieducar_synchronizations, -> {
    where(stateable_type: 'IeducarApiSynchronization').joins(
      'INNER JOIN ieducar_api_synchronizations
               ON ieducar_api_synchronizations.id = worker_batches.stateable_id'
    )
  }

  scope :by_full_synchronizations, -> {
    by_ieducar_synchronizations.merge(IeducarApiSynchronization.by_full_synchronizations)
  }

  scope :by_partial_synchronizations, -> {
    by_ieducar_synchronizations.merge(IeducarApiSynchronization.by_partial_synchronizations)
  }

  scope :by_status, ->(status) { where(status: status) }
  scope :completed, -> { by_status(ApiSynchronizationStatus::COMPLETED) }

  def done
    $REDIS_DB.get(redis_key).to_i
  end

  def all_workers_finished?
    total_workers == done_workers
  end

  def done_percentage
    return 0   if total_workers.zero?
    return 100 if all_workers_finished?

    ((done.to_f / total_workers.to_f) * 100).round(0)
  end

  def increment
    return if all_workers_finished?

    new_count = $REDIS_DB.incr(redis_key)

    if new_count == total_workers
      yield if block_given?

      update!(done_workers: new_count, status: ApiSynchronizationStatus::COMPLETED)
      $REDIS_DB.del(redis_key)
    end
  end

  def mark_as_error!
    update(status: ApiSynchronizationStatus::ERROR)
  end

  private

  def redis_key
    "worker_batch:#{id}:done_workers"
  end

  def reset
    self.total_workers = 0
    self.done_workers = 0
    worker_states.delete_all
    $REDIS_DB.del(redis_key)
  end
end