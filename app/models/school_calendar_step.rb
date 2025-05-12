class SchoolCalendarStep < ActiveRecord::Base
  include SchoolTermable

  acts_as_copy_target

  audited associated_with: :school_calendar, except: :school_calendar_id

  belongs_to :school_calendar
  has_many :ieducar_api_exam_postings, dependent: :destroy

  validate :start_at_must_not_have_conflicting_date, if: :school_calendar
  validate :end_at_must_not_have_conflicting_date, if: :school_calendar
  validate :start_at_must_be_less_than_end_at
  validate :end_date_less_than_start_date_for_posting

  scope :by_school_calendar_id, ->(school_calendar_id) { where(school_calendar_id: school_calendar_id) }
  scope :by_unity, ->(unity_id) { joins(:school_calendar).where(school_calendars: { unity_id: unity_id }) }
  scope :by_year, ->(year) { joins(:school_calendar).where(school_calendars: { year: year }) }
  scope :by_step_number, ->(step_number) { where(step_number: step_number) }
  scope :by_step_year, ->(year) { where('EXTRACT(YEAR FROM start_at) = ?', year) }
  scope :started_after_and_before, lambda { |date|
    where(arel_table[:start_at].lteq(date)).where(arel_table[:end_at].gteq(date))
  }
  scope :posting_date_after_and_before, lambda { |date|
    where(arel_table[:start_date_for_posting].lteq(date).and(arel_table[:end_date_for_posting].gteq(date)))
  }
  scope :by_date_range, lambda { |start_date, end_date|
    where.not(
      arel_table[:start_at].gt(end_date.to_date).or(
        arel_table[:end_at].lt(start_date.to_date)
      )
    )
  }
  scope :ordered, -> { order(:start_at) }

  delegate :unity, to: :school_calendar

  def school_calendar_step_day?(date)
    step_from_date = school_calendar.step(date)

    return false unless step_from_date.eql?(self)

    school_calendar.school_day?(date)
  end

  def school_calendar_day_allows_entry?(date)
    step_from_date = school_calendar.step(date)

    return false unless step_from_date.eql?(self)

    school_calendar.day_allows_entry?(date)
  end

  def school_day_dates
    return if start_at.blank? || end_at.blank? || school_calendar.blank?

    dates = []

    (start_at..end_at).each do |date|
      dates << date if school_calendar.school_day?(date)
    end

    dates
  end

  def school_calendar_parent
    school_calendar
  end

  private

  def steps
    return if school_calendar.blank?

    school_calendar.steps
  end

  def start_at_must_be_less_than_end_at
    return if errors[:start_at].any? || errors[:end_at].any?

    errors.add(:start_at, :must_be_less_than_end_at) if start_at.to_date >= end_at.to_date
  end

  def end_date_less_than_start_date_for_posting
    return if start_date_for_posting.blank? || end_date_for_posting.blank?

    return if end_date_for_posting >= start_date_for_posting

    errors.add(:end_date_for_posting, :must_be_greater_than_start_date_for_posting)
  end

  def start_at_must_not_have_conflicting_date
    school_calendars = SchoolCalendar.by_unity_id(unity).where.not(id: school_calendar_id)

    exist_conflicting_steps = school_calendars.any? { |school_calendar|
      school_calendar.school_day?(start_at)
    }

    errors.add(:start_at, :must_not_have_conflicting_steps) if exist_conflicting_steps
  end

  def end_at_must_not_have_conflicting_date
    school_calendars = SchoolCalendar.by_unity_id(unity).where.not(id: school_calendar_id)

    exist_conflicting_steps = school_calendars.any? { |school_calendar|
      school_calendar.school_day?(end_at)
    }

    errors.add(:end_at, :must_not_have_conflicting_steps) if exist_conflicting_steps
  end
end
