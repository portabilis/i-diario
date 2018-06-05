class IeducarApiSynchronization < ActiveRecord::Base
  acts_as_copy_target

  has_enumeration_for :status, with: ApiSynchronizationStatus, create_helpers: true,
    create_scopes: true

  belongs_to :ieducar_api_configuration
  belongs_to :author, class_name: "User"

  validates :ieducar_api_configuration, presence: true

  delegate :to_api, to: :ieducar_api_configuration

  scope :unnotified, -> { where(notified: false) }

  def self.completed_unnotified
    self.completed.unnotified.last
  end

  def self.last_error
    self.error.unnotified.last
  end

  def mark_as_error!(message)
    update_columns(
      status: ApiSynchronizationStatus::ERROR,
      error_message: message
    )
  end

  def mark_as_completed!
    update_column(:status, ApiSynchronizationStatus::COMPLETED)
  end

  def notified!
    update_column(:notified, true)
  end

  def set_job_id!(job_id)
    update_attribute(:job_id, job_id)
  end
end
