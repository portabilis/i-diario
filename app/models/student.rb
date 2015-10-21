class Student < ActiveRecord::Base
  acts_as_copy_target

  has_one :user

  has_and_belongs_to_many :users

  has_many :***REMOVED***, dependent: :restrict_with_error

  validates :name, presence: true
  validates :api_code, presence: true, if: :api?

  scope :api, -> { where(arel_table[:api].eq(true)) }
  scope :ordered, -> { order(:name) }

  def self.search(value)
    relation = all

    if value.present?
      relation = relation.where(%Q(
        name ILIKE :text OR api_code = :code
      ), text: "%#{value}%", code: value)
    end

    relation
  end

  def to_s
    name
  end

  def average(discipline_id, school_calendar_step_id)
    step = SchoolCalendarStep.find(school_calendar_step_id)
    scores = DailyNoteStudent.by_discipline_id(discipline_id)
      .by_test_date_between(step.start_at, step.end_at)

    test_setting = TestSetting.find_by(
      exam_setting_type: ExamSettingTypes::GENERAL,
      year: step.school_calendar.year
    )
    unless test_setting
      test_setting = TestSetting.find_by(
        year: step.school_calendar.year,
        school_term: step.school_term
      )
    end

    test_setting.fix_tests? ? scores.sum(:note) : (scores.sum(:note) / scores.count)
  end
end
