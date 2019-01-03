class SchoolCalendarClassroomStep < ActiveRecord::Base
  include SchoolTermable

  acts_as_copy_target

  belongs_to :school_calendar_classroom
  has_many :ieducar_api_exam_postings, dependent: :destroy

  validate :start_at_must_be_less_than_end_at
  validate :dates_for_posting_less_than_start_date
  validate :end_date_less_than_start_date_for_posting

  scope :by_school_day, lambda { |date| where('? BETWEEN start_at AND end_at', date) }
  scope :by_classroom, lambda { |classroom|
    joins(school_calendar_classroom: [:school_calendar]).
    where(school_calendar_classrooms: { classroom_id: classroom })
  }
  scope :by_school_calendar_id, lambda { |school_calendar_id|
    joins(:school_calendar_classroom).
    where(school_calendar_classrooms: { school_calendar_id: school_calendar_id })
  }
  scope :started_after_and_before, lambda { |date|
    where(arel_table[:start_at].lteq(date)).
    where(arel_table[:end_at].gteq(date))
  }
  scope :posting_date_after_and_before, lambda { |date|
    where(arel_table[:start_date_for_posting].lteq(date).and(arel_table[:end_date_for_posting].gteq(date)))
  }
  scope :by_step_year, lambda { |year| where('extract(year from start_at) = ?', year) }
  scope :ordered, -> { order(:start_at) }

  delegate :classroom, :school_calendar_id, to: :school_calendar_classroom

  def school_calendar_step_day?(date)
    step_from_date = school_calendar_classroom.classroom_step(date)

    if !step_from_date.eql?(self)
      false
    else
      school_calendar.school_day?(date, school_calendar_classroom.classroom.grade, school_calendar_classroom.classroom)
    end
  end

  def test_setting
    TestSetting.where(
      TestSetting.arel_table[:year].eq(school_calendar_classroom.school_calendar.year)
        .and(
          TestSetting.arel_table[:exam_setting_type].eq(ExamSettingTypes::GENERAL)
          .or(TestSetting.arel_table[:school_term].eq(school_calendar_classroom.school_term(start_at)))
        )
    )
    .order(school_term: :desc)
    .first
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

    if start_at.to_date >= end_at.to_date
      errors.add(:start_at, :must_be_less_than_end_at)
    end
  end

  def dates_for_posting_less_than_start_date
    if start_at.present?
      errors.add(:start_date_for_posting, :must_be_greater_than_start_at) if start_date_for_posting && start_date_for_posting < start_at
      errors.add(:end_date_for_posting, :must_be_greater_than_start_at) if end_date_for_posting && end_date_for_posting < start_at
    end
  end

  def end_date_less_than_start_date_for_posting
    if start_date_for_posting.present? && end_date_for_posting.present?
      errors.add(:end_date_for_posting, :must_be_greater_than_start_date_for_posting) if end_date_for_posting < start_date_for_posting
    end
  end
end
