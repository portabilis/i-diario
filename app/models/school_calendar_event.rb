class SchoolCalendarEvent < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :school_calendar

  has_enumeration_for :event_type, with: EventTypes

  validates :description, :event_type, :event_date, :school_calendar_id, presence: true

  scope :ordered, -> { order(arel_table[:event_date]) }

  def to_s
    description
  end
end
