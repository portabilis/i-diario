class WorkerState < ActiveRecord::Base
  belongs_to :user

  validates :job_id, :kind, :user, presence: true

  def mark_with_error!(message)
    update_columns(
      status: ApiSynchronizationStatus::ERROR,
      error_message: message
    )
  end

  def mark_as_completed!
    update_column :status, ApiSynchronizationStatus::COMPLETED
  end
end
