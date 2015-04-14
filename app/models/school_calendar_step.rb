class SchoolCalendarStep < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :school_calendar

  belongs_to :school_calendar

  validates :start_at, :end_at, presence: true

  scope :ordered, -> { order(arel_table[:start_at]) }
end
