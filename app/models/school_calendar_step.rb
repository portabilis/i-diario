class SchoolCalendarStep < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :school_calendar, except: :school_calendar_id

  belongs_to :school_calendar
  has_many :descriptive_exams, dependent: :restrict_with_exception
  has_many :ieducar_api_exam_postings, dependent: :restrict_with_exception
  has_many :conceptual_exams, dependent: :restrict_with_exception
  has_many :transfer_notes, dependent: :restrict_with_exception
  has_many :school_term_recovery_diary_records, dependent: :restrict_with_exception

  validates :start_at, :end_at, :start_date_for_posting, :end_date_for_posting, presence: true

  validate :start_at_must_be_in_school_calendar_year, if: :school_calendar
  validate :end_at_must_be_valid, if: :school_calendar
  validate :start_at_must_be_less_than_end_at

  validate :dates_for_posting_less_than_start_date
  validate :end_date_less_than_start_date_for_posting

  scope :by_school_calendar_id, lambda { |school_calendar_id| where(school_calendar_id: school_calendar_id) }
  scope :started_after_and_before, lambda { |date| where(arel_table[:start_at].lteq(date)).
                                                  where(arel_table[:end_at].gteq(date)) }
  scope :posting_date_after_and_before, lambda { |date| where(arel_table[:start_date_for_posting].lteq(date).and(arel_table[:end_date_for_posting].gteq(date))) }
  scope :ordered, -> { order(arel_table[:start_at]) }

  delegate :unity, to: :school_calendar

  def to_s
    "#{school_term} (#{localized.start_at} a #{localized.end_at})"
  end

  def to_number
    return unless school_calendar
    (school_calendar.steps.ordered.index(self) || 0) + 1
  end

  def school_calendar_step_day?(date)
    step_from_date = school_calendar.step(date)

    if !step_from_date.eql?(self)
      false
    else
      school_calendar.school_day?(date)
    end
  end

  def number_of_school_days
    return unless start_at || end_at || school_calendar

    days = 0
    (start_at..end_at).each do |date|
      days += 1 if school_calendar.school_day?(date)
    end
    days
  end

  def school_day_dates
    return unless start_at || end_at || school_calendar

    dates = []
    (start_at..end_at).each do |date|
      dates << date if school_calendar.school_day?(date)
    end
    dates
  end

  def school_term
    school_term = school_calendar.school_term(start_at).to_s

    case
    when school_term.end_with?(SchoolTermTypes::BIMESTER)
      I18n.t("enumerations.bimesters.#{school_term}")
    when school_term.end_with?(SchoolTermTypes::TRIMESTER)
      I18n.t("enumerations.trimesters.#{school_term}")
    when school_term.end_with?(SchoolTermTypes::SEMESTER)
      I18n.t("enumerations.semesters.#{school_term}")
    end
  end

  def test_setting
    TestSetting.where(
      TestSetting.arel_table[:year].eq(school_calendar.year)
        .and(TestSetting.arel_table[:exam_setting_type].eq(ExamSettingTypes::GENERAL)
               .or(TestSetting.arel_table[:school_term].eq(school_calendar.school_term(start_at)))
        )
    )
    .order(school_term: :desc)
    .first
  end

  private

  def start_at_must_be_in_school_calendar_year
    return if errors[:start_at].any? || school_calendar.errors[:year].any?

    errors.add(:start_at, :must_be_in_school_calendar_year) if start_at.to_date.year != school_calendar.year.to_i
  end

  def end_at_must_be_valid
    return if errors[:end_at].any? || school_calendar.errors[:year].any?

    valid_date = "28/02/#{school_calendar.year.to_i + 1}"
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
