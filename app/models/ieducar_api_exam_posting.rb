class IeducarApiExamPosting < ActiveRecord::Base
  acts_as_copy_target

  has_enumeration_for :post_type, with: ApiPostingTypes, create_scopes: true
  has_enumeration_for :status, with: ApiPostingStatus, create_helpers: true,
    create_scopes: true

  belongs_to :ieducar_api_configuration
  belongs_to :school_calendar_step
  belongs_to :author, class_name: "User"

  validates :ieducar_api_configuration, :school_calendar_step, presence: true

  delegate :to_api, to: :ieducar_api_configuration

  def self.completed
    self.completed.last
  end

  def self.last_error
    self.error.last
  end

  def syncronization_in_progress?
    status == ApiSyncronizationStatus::STARTED
  end

  def mark_as_error!(message)
    update_columns(
      status: ApiSyncronizationStatus::ERROR,
      error_message: message
    )
  end

  def mark_as_completed!(message)
    update_columns(
      status: ApiSyncronizationStatus::COMPLETED,
      message: message
    )
  end
end
