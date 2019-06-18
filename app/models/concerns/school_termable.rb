module SchoolTermable
  extend ActiveSupport::Concern

  included do
    validates_date :start_date_for_posting, :end_date_for_posting
    validates :start_at, :end_at, :start_date_for_posting, :end_date_for_posting, presence: true
    validate :start_at_must_be_in_school_calendar_year, if: :school_calendar
  end

  def to_s
    "#{school_term} (#{localized.start_at} a #{localized.end_at})"
  end

  def to_number
    step_number
  end

  def step_type_description
    @step_type_description ||= school_calendar_parent.step_type_description
  end

  def school_term
    "#{to_number}º #{step_type_description}"
  end

  private

  def start_at_must_be_in_school_calendar_year
    return if errors[:start_at].any? || school_calendar.errors[:year].any?

    errors.add(:start_at, :must_be_in_school_calendar_year) if start_at.to_date.year != school_calendar.year.to_i
  end
end
