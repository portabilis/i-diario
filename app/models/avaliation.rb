class Avaliation < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  before_destroy :try_destroy_daily_notes

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar
  belongs_to :test_setting
  belongs_to :test_setting_test
  has_many :daily_notes, dependent: :restrict_with_error
  has_many :teacher_discipline_classrooms, -> { where(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(Avaliation.arel_table[:discipline_id])) }, through: :classroom

  validates :unity, :classroom, :discipline, :test_date, :class_number, :test_setting,
              :school_calendar, presence: true
  validates :test_setting_test, presence: true, if: :fix_tests?
  validates :weight, presence: true,
                     if: :allow_break_up?

  validates :description, presence: true, unless: :fix_tests?

  validate :unique_test_setting_test_per_step, if: -> { fix_tests? && !allow_break_up? }
  validate :test_setting_test_weight_available, if: :allow_break_up?
  validate :is_school_day?
  validate :classroom_score_type_must_be_numeric, if: :should_validate_classroom_score_type?

  scope :by_teacher, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }
  scope :teacher_avaliations, lambda { |teacher_id, classroom_id, discipline_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id, discipline_id: discipline_id}) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_test_date_between, lambda { |start_at, end_at| where(test_date: start_at.to_date..end_at.to_date) }
  scope :by_test_setting_test_id, lambda { |test_setting_test_id| where(test_setting_test_id: test_setting_test_id) }
  scope :ordered, -> { order(arel_table[:test_date]) }

  def to_s
    test_setting_test || description
  end

  def description_to_teacher
    I18n.l(test_date) + ' - ' + (fix_tests? ? test_setting_test.to_s : (description ? description : ''))
  end

  def self.data_for_select2
    where(nil).map do |avaliation|
      {
        id: avaliation.id,
        name: avaliation.description_to_teacher,
        text: avaliation.description_to_teacher
      }
    end.to_json
  end

  def fix_tests?
    return false if test_setting.nil?
    test_setting.fix_tests?
  end

  def allow_break_up?
    test_setting_test && test_setting_test.allow_break_up
  end

  private

  def is_school_day?
    return unless school_calendar && test_date

    errors.add(:test_date, :must_be_school_day) if !school_calendar.school_day? test_date
  end

  def should_validate_classroom_score_type?
    classroom
  end

  def classroom_score_type_must_be_numeric
    unless classroom.exam_rule && classroom.exam_rule.score_type == ScoreTypes::NUMERIC
      errors.add(:classroom, :classroom_score_type_must_be_numeric)
    end
  end

  def step
    return unless school_calendar
    school_calendar.step(test_date)
  end

  def unique_test_setting_test_per_step
    return unless step

    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_discipline_id(discipline)
                            .by_test_setting_test_id(test_setting_test_id)
                            .by_test_date_between(step.start_at, step.end_at)
    avaliations = avaliations.where(Avaliation.arel_table[:id].not_eq(id)) if persisted?

    errors.add(:test_setting_test, :unique_per_step) if avaliations.any?
  end

  def test_setting_test_weight_available
    return unless step && weight

    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_discipline_id(discipline)
                            .by_test_setting_test_id(test_setting_test_id)
                            .by_test_date_between(step.start_at, step.end_at)
    avaliations = avaliations.where(Avaliation.arel_table[:id].not_eq(id)) if persisted?

    total_weight_of_existing_avaliations = avaliations.any? ? avaliations.inject(0) { |sum, avaliation| sum + avaliation.weight } : 0
    if total_weight_of_existing_avaliations == test_setting_test.weight
      errors.add(:test_setting_test, :unavailable_weight)
    elsif (total_weight_of_existing_avaliations + weight) > test_setting_test.weight
      errors.add(:weight, :less_than_or_equal_to, count: test_setting_test.weight - total_weight_of_existing_avaliations)
    elsif (weight <= 0)
      errors.add(:weight, :greater_than, count: 0.0)
    end
  end

  def try_destroy_daily_notes
    can_destroy_daily_notes = !daily_notes.any? { |daily_note| daily_note.students.any? { |daily_note_student| daily_note_student.note } }
    daily_notes.destroy_all if can_destroy_daily_notes
  end
end