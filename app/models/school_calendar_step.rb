class SchoolCalendarStep < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :school_calendar, except: :school_calendar_id

  belongs_to :school_calendar

  validates :start_at, :end_at, :start_date_for_posting, :end_date_for_posting, presence: true

  validate :start_at_must_be_in_school_calendar_year, if: :school_calendar
  validate :end_at_must_be_in_school_calendar_year, if: :school_calendar
  validate :start_at_must_be_less_than_end_at

  scope :ordered, -> { order(arel_table[:start_at]) }
  scope :started_after_and_before, lambda { |date| where(arel_table[:start_at].lteq(date)).
                                                  where(arel_table[:end_at].gteq(date)) }

  def to_s
    "#{localized.start_at} a #{localized.end_at}"
  end

  private

  def start_at_must_be_in_school_calendar_year
    return if errors[:start_at].any? || school_calendar.errors[:year].any?

    errors.add(:start_at, :must_be_in_school_calendar_year) if start_at.to_date.year != school_calendar.year.to_i
  end

  def end_at_must_be_in_school_calendar_year
    return if errors[:end_at].any? || school_calendar.errors[:year].any?

    errors.add(:end_at, :must_be_in_school_calendar_year) if end_at.to_date.year != school_calendar.year.to_i
  end

  def start_at_must_be_less_than_end_at
    return if errors[:start_at].any? || errors[:end_at].any?

    if start_at.to_date >= end_at.to_date
      errors.add(:start_at, :must_be_less_than_end_at)
    end
  end
end
