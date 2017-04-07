class SchoolCalendarClassroomStep < ActiveRecord::Base
  belongs_to :school_calendar_classroom

  scope :ordered, -> { order(arel_table[:start_at]) }

  validates :start_at, :end_at, :start_date_for_posting, :end_date_for_posting, presence: true

  validate :start_at_must_be_in_school_calendar_year, if: :school_calendar
  validate :end_at_must_be_valid, if: :school_calendar
  validate :start_at_must_be_less_than_end_at

  validate :dates_for_posting_less_than_start_date
  validate :end_date_less_than_start_date_for_posting

  scope :by_classroom, lambda { |classroom| joins(school_calendar_classroom: [:school_calendar]).where(school_calendar_classrooms: { classroom_id: classroom })   }
  scope :by_school_calendar_id, lambda { |school_calendar_id| joins(:school_calendar_classroom).where(school_calendar_classrooms: { school_calendar_id: school_calendar_id })   }
  scope :started_after_and_before, lambda { |date| where(arel_table[:start_at].lteq(date)).where(arel_table[:end_at].gteq(date)) }
  scope :posting_date_after_and_before, lambda { |date| where(arel_table[:start_date_for_posting].lteq(date).and(arel_table[:end_date_for_posting].gteq(date))) }

  delegate :classroom, to: :school_calendar_classroom

  def to_s
    "#{school_term} (#{localized.start_at} a #{localized.end_at})"
  end

  def to_number
    return unless school_calendar_classroom
    (school_calendar_classroom.classroom_steps.ordered.index(self) || 0) + 1
  end

  def school_calendar_id
    school_calendar_classroom.school_calendar_id
  end

  def school_calendar_step_day?(date)
    step_from_date = school_calendar_classroom.classroom_step(date)

    if !step_from_date.eql?(self)
      false
    else
      school_calendar.school_day?(date, nil, school_calendar_classroom.classroom)
    end
  end

  def school_term
    school_term = school_calendar_classroom.school_term(start_at).to_s

    case
    when school_term.end_with?(SchoolTermTypes::BIMESTER)
      I18n.t("enumerations.bimesters.#{school_term}")
    when school_term.end_with?(SchoolTermTypes::TRIMESTER)
      I18n.t("enumerations.trimesters.#{school_term}")
    when school_term.end_with?(SchoolTermTypes::SEMESTER)
      I18n.t("enumerations.semesters.#{school_term}")
    when school_term.end_with?(SchoolTermTypes::YEARLY)
      I18n.t("enumerations.year.#{school_term}")
    end
  end

  def test_setting
    TestSetting.where(
      TestSetting.arel_table[:year].eq(school_calendar_classroom.school_calendar.year)
        .and(TestSetting.arel_table[:exam_setting_type].eq(ExamSettingTypes::GENERAL)
               .or(TestSetting.arel_table[:school_term].eq(school_calendar_classroom.school_term(start_at)))
        )
    )
    .order(school_term: :desc)
    .first
  end

  def school_calendar
    if school_calendar_classroom.present?
      school_calendar_classroom.school_calendar
    end
  end

  private

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
