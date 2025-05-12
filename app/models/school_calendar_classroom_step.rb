class SchoolCalendarClassroomStep < ApplicationRecord
  include SchoolTermable

  audited

  acts_as_copy_target

  belongs_to :school_calendar_classroom
  has_many :ieducar_api_exam_postings, dependent: :destroy

  validate :start_at_must_be_less_than_end_at
  validate :end_date_less_than_start_date_for_posting

  scope :by_school_day, ->(date) { where('? BETWEEN start_at AND end_at', date) }
  scope :by_classroom, lambda { |classroom|
    joins(school_calendar_classroom: [:school_calendar])
      .where(school_calendar_classrooms: { classroom_id: classroom })
  }
  scope :by_school_calendar_id, lambda { |school_calendar_id|
    joins(:school_calendar_classroom)
      .where(school_calendar_classrooms: { school_calendar_id: school_calendar_id })
  }
  scope :started_after_and_before, lambda { |date|
    where(arel_table[:start_at].lteq(date))
      .where(arel_table[:end_at].gteq(date))
  }
  scope :posting_date_after_and_before, lambda { |date|
    where(arel_table[:start_date_for_posting].lteq(date).and(arel_table[:end_date_for_posting].gteq(date)))
  }
  scope :by_step_number, ->(step_number) { where(step_number: step_number) }
  scope :by_step_year, ->(year) { where('EXTRACT(YEAR FROM start_at) = ?', year) }
  scope :by_date_range, lambda { |start_date, end_date|
    where.not(
      arel_table[:start_at].gt(end_date.to_date).or(
        arel_table[:end_at].lt(start_date.to_date)
      )
    )
  }
  scope :ordered, -> { order(:start_at) }

  delegate :classroom, :classroom_id, :school_calendar_id, to: :school_calendar_classroom

  def school_calendar_step_day?(date)
    step_from_date = school_calendar_classroom.classroom_step(date)

    return false unless step_from_date.eql?(self)

    school_calendar.school_day?(date, classroom.grade_ids, classroom_id)
  end

  def school_calendar_day_allows_entry?(date)
    step_from_date = school_calendar_classroom.classroom_step(date)

    return false unless step_from_date.eql?(self)

    school_calendar.day_allows_entry?(date, classroom.grade_ids, classroom_id)
  end

  def school_calendar
    school_calendar_classroom.school_calendar if school_calendar_classroom.present?
  end

  def school_calendar_parent
    school_calendar_classroom
  end

  private

  def steps
    return if school_calendar_classroom.blank?

    school_calendar_classroom.classroom_steps
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
end
