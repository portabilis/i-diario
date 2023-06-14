class SchoolCalendarEventBatch < ApplicationRecord
  audited

  has_many :school_calendar_events, dependent: :nullify, foreign_key: 'batch_id'

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
  scope :by_year, ->(year) { where(year: year) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_status, ->(status) { where(batch_status: status) }
  scope :by_date, lambda { |date|
    where(
      '? BETWEEN school_calendar_event_batches.start_date AND school_calendar_event_batches.end_date',
      date.to_date
    )
  }
  scope :by_description, lambda { |description|
    where('unaccent(school_calendar_event_batches.description) ILIKE unaccent(?)', "%#{description}%")
  }

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
