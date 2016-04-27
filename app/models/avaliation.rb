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

  has_one  :recovery_diary_record, through: :avaliation_recovery_diary_record
  has_one  :avaliation_recovery_diary_record

  has_many :daily_notes, dependent: :restrict_with_error
  has_many :teacher_discipline_classrooms, -> { where(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(Avaliation.arel_table[:discipline_id])) }, through: :classroom

  validates :unity,             presence: true
  validates :classroom,         presence: true
  validates :discipline,        presence: true
  validates :test_date,         presence: true
  validates :classes,           presence: true
  validates :school_calendar,   presence: true
  validates :test_setting,      presence: true
  validates :test_setting_test, presence: true, if: :fix_tests?
  validates :description,       presence: true, if: -> { !fix_tests? || allow_break_up? }
  validates :weight,            presence: true, if: :allow_break_up?

  validate :uniqueness_of_avaliation
  validate :unique_test_setting_test_per_step,    if: -> { fix_tests? && !allow_break_up? }
  validate :test_setting_test_weight_available,   if: :allow_break_up?
  validate :classroom_score_type_must_be_numeric, if: :should_validate_classroom_score_type?
  validate :is_school_day?
  validate :is_school_term_day?

  scope :teacher_avaliations, lambda { |teacher_id, classroom_id, discipline_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id, discipline_id: discipline_id}) }
  scope :by_teacher, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }
  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_test_date, lambda { |test_date| where(test_date: test_date) }
  scope :by_test_date_between, lambda { |start_at, end_at| where(test_date: start_at.to_date..end_at.to_date) }
  scope :by_classes, lambda { |classes| where("classes && ARRAY#{classes}::INTEGER[]") }
  scope :by_description, lambda { |description| joins(arel_table.join(TestSettingTest.arel_table, Arel::Nodes::OuterJoin)
                                                                .on(TestSettingTest.arel_table[:id]
                                                                .eq(arel_table[:test_setting_test_id])).join_sources)
                                                .where('avaliations.description ILIKE ? OR test_setting_tests.description ILIKE ?', "%#{description}%", "%#{description}%") }
  scope :by_test_setting_test_id, lambda { |test_setting_test_id| where(test_setting_test_id: test_setting_test_id) }
  scope :ordered, -> { order(arel_table[:test_date]) }

  def to_s
    !test_setting_test || allow_break_up? ? description : test_setting_test.to_s
  end

  def classes=(classes)
    write_attribute(:classes, classes ? classes.split(',').sort.map(&:to_i) : classes)
  end

  def description_to_teacher
    I18n.l(test_date) + ' - ' + (self.to_s || '')
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
    return unless school_calendar && test_date && classroom

    errors.add(:test_date, :must_be_school_day) if !school_calendar.school_day?(test_date, classroom.grade.id, classroom.id)
  end

  def is_school_term_day?
    return if test_setting.nil? || test_setting.exam_setting_type == ExamSettingTypes::GENERAL

    errors.add(:test_date, :must_be_school_term_day) if !school_calendar.school_term_day?(test_setting.school_term, test_date)
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

  def uniqueness_of_avaliation
    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_discipline_id(discipline)
                            .by_test_date(test_date)
                            .by_classes(classes)
    avaliations = avaliations.where.not(id: id) if persisted?

    errors.add(:classes, :uniqueness_of_avaliation, count: classes.count) if avaliations.any?
  end

  def unique_test_setting_test_per_step
    return unless step

    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_discipline_id(discipline)
                            .by_test_setting_test_id(test_setting_test_id)
                            .by_test_date_between(step.start_at, step.end_at)
    avaliations = avaliations.where.not(id: id) if persisted?

    errors.add(:test_setting_test, :unique_per_step) if avaliations.any?
  end

  def test_setting_test_weight_available
    return unless step && weight

    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_discipline_id(discipline)
                            .by_test_setting_test_id(test_setting_test_id)
                            .by_test_date_between(step.start_at, step.end_at)
    avaliations = avaliations.where.not(id: id) if persisted?

    total_weight_of_existing_avaliations = avaliations.any? ? avaliations.inject(0) { |sum, avaliation| avaliation.weight ? sum + avaliation.weight : 0 } : 0
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
