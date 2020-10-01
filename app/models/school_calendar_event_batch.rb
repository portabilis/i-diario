class SchoolCalendarEventBatch < ActiveRecord::Base
  audited

  include Filterable

  has_many :school_calendar_events, dependent: :destroy

  has_enumeration_for :event_type, with: EventTypes
  has_enumeration_for :batch_status, with: BatchStatus, create_helpers: true

  validates :description, :event_type, :start_date, :end_date, :year, :periods, presence: true
  validates :legend, presence: true, exclusion: { in: %w(F f N n .) }, if: :should_validate_legend?
  validates :start_date, presence: true, date: true, timeliness: {
    on_or_before: :end_date,
    type: :date,
    on_or_before_message: :on_or_before_message
  }
  validates :end_date, presence: true, date: true, timeliness: {
    on_or_after: :start_date,
    type: :date,
    on_or_after_message: :on_or_after_message
  }

  scope :ordered, -> { order(:start_date) }

  def mark_with_error!(message)
    update(
      batch_status: BatchStatus::ERROR,
      error_message: message
    )
  end

  def duration
    "#{I18n.l(start_date)} à #{I18n.l(end_date)}"
  end

  def should_validate_legend?
    [EventTypes::EXTRA_SCHOOL, EventTypes::NO_SCHOOL_WITH_FREQUENCY].exclude?(event_type)
  end
end
