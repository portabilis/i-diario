class SchoolCalendarEventBatch < ActiveRecord::Base
  audited

  include Filterable

  has_many :school_calendar_events, dependent: :destroy

  has_enumeration_for :event_type, with: EventTypes
  has_enumeration_for :batch_status, with: BatchStatus, create_helpers: true

  scope :ordered, -> { order(:start_date) }

  def mark_with_error!(message)
    update(
      batch_status: BatchStatus::ERROR,
      error_message: message
    )
  end
end
