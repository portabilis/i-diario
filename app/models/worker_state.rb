class WorkerState < ActiveRecord::Base
  include LifeCycleTimeLoggable

  belongs_to :user
  belongs_to :worker_batch

  scope :by_worker_batch_id, ->(worker_batch_id) { where(worker_batch_id: worker_batch_id) }
  scope :by_kind, ->(kind) { where(kind: kind) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_meta_data, ->(key, value) { where('meta_data->>? = ?', key, value.to_s) }

  validates :kind, presence: true

  def meta_data
    self[:meta_data].symbolize_keys
  end

  def mark_with_error!(message)
    update(
      status: ApiSynchronizationStatus::ERROR,
      error_list: [message]
    )
  end

  def add_error!(message)
    update(status: ApiSynchronizationStatus::ERROR) unless error?

    update(error_list: error_list << message)
  end

  def mark_as_completed!
    update(
      status: ApiSynchronizationStatus::COMPLETED
    )
  end

  def enqueued!
    update(
      status: ApiSynchronizationStatus::ENQUEUED
    )
  end
end
