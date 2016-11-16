class SchoolCalendarClassroomStep < ActiveRecord::Base
  belongs_to :school_calendar_classroom

  scope :ordered, -> { order(arel_table[:start_at]) }

  validates :start_at, :end_at, :start_date_for_posting, :end_date_for_posting, presence: true

  validate :start_at_must_be_in_school_calendar_year, if: :school_calendar
  validate :end_at_must_be_valid, if: :school_calendar
  validate :start_at_must_be_less_than_end_at

  validate :dates_for_posting_less_than_start_date
  validate :end_date_less_than_start_date_for_posting

  private

  def school_calendar
    if school_calendar_classroom.present?
      school_calendar_classroom.school_calendar
    end
  end

  def start_at_must_be_in_school_calendar_year
    return if errors[:start_at].any? || school_calendar_classroom.school_calendar.errors[:year].any?

    errors.add(:start_at, :must_be_in_school_calendar_year) if start_at.to_date.year != school_calendar_classroom.school_calendar.year.to_i
  end

  def end_at_must_be_valid
    return if errors[:end_at].any? || school_calendar_classroom.school_calendar.errors[:year].any?

    valid_date = "28/02/#{school_calendar_classroom.school_calendar.year.to_i + 1}"
    errors.add(:end_at, :end_at_must_be_valid, valid_date: valid_date) if end_at.to_date > valid_date.to_date
  end

  def start_at_must_be_less_than_end_at
    return if errors[:start_at].any? || errors[:end_at].any?

    if start_at.to_date >= end_at.to_date
      errors.add(:start_at, :must_be_less_than_end_at)
    end
  end

  def dates_for_posting_less_than_start_date
    if start_at
      errors.add(:start_date_for_posting, :must_be_greater_than_start_at) if start_date_for_posting && start_date_for_posting < start_at
      errors.add(:end_date_for_posting, :must_be_greater_than_start_at) if end_date_for_posting && end_date_for_posting < start_at
    end
  end

  def end_date_less_than_start_date_for_posting
    if start_date_for_posting && end_date_for_posting
      errors.add(:end_date_for_posting, :must_be_greater_than_start_date_for_posting) if end_date_for_posting < start_date_for_posting
    end
  end
end
