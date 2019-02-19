class WorkerState < ActiveRecord::Base
  include LifeCycleTimeLoggable

  belongs_to :user
  belongs_to :worker_batch

  validates :kind, presence: true

  def mark_with_error!(message)
    update(
      status: ApiSynchronizationStatus::ERROR,
      error_message: message
    )
  end

  def mark_as_completed!
    update(
      status: ApiSynchronizationStatus::COMPLETED
    )
  end
end
