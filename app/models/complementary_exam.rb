class ComplementaryExam < ApplicationRecord
  include Audit
  include Stepable
  include ColumnsLockable
  include TeacherRelationable

  not_updatable only: [:classroom_id, :discipline_id]
  teacher_relation_columns only: [:classroom, :discipline]

  acts_as_copy_target

  audited
  has_associated_audits

  before_destroy :valid_for_destruction?

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :complementary_exam_setting

  has_many :students, -> { includes(:student).ordered },
    class_name: 'ComplementaryExamStudent',
    dependent: :destroy

  # A lista traz uma linha por matrícula e só a linha da matrícula enturmada na data grava, como no diário de
  # avaliações numéricas. Linha marcada com _destroy não passa pelo reject_if (will_be_destroyed? do Rails): o
  # aluno removido da lista é excluído mesmo com a linha fora da data.
  accepts_nested_attributes_for :students, allow_destroy: true, reject_if: proc { |attributes|
    !ActiveRecord::Type::Boolean.new.cast(attributes[:active])
  }

  scope :by_teacher_id,
        lambda { |teacher_id|
          joins(discipline: :teacher_discipline_classrooms)
            .where(teacher_discipline_classrooms: { teacher_id: teacher_id })
            .distinct
        }

  scope :by_complementary_exam_setting, lambda { |complementary_exam_setting_id| where(complementary_exam_setting_id: complementary_exam_setting_id) }
  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_grade_id, lambda { |grade_id| joins(:classroom).merge(Classroom.by_grade(grade_id)) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_student_id, lambda { |student_id| joins(:students).where(complementary_exam_students: { student_id: student_id }) }
  scope :by_recorded_at, lambda { |recorded_at| where(recorded_at: recorded_at) }
  scope :by_date_range, lambda { |start_at, end_at| where(recorded_at: start_at.to_date..end_at.to_date) }
  scope :by_affected_score, lambda { |affected_score| joins(:complementary_exam_setting).merge(ComplementaryExamSetting.by_affected_score(affected_score)) }
  scope :by_calculation_type, lambda { |calculation_type| joins(:complementary_exam_setting).merge(ComplementaryExamSetting.by_calculation_type(calculation_type)) }
  scope :ordered, -> { order(recorded_at: :desc) }

  validates :unity, presence: true
  validates :discipline, presence: true
  validates :complementary_exam_setting, presence: true
  validates :recorded_at, posting_date: true

  validate :recorded_at_year_in_settings_year
  validate :at_least_one_score

  delegate :maximum_score, to: :complementary_exam_setting
  before_validation :self_assign_to_students

  def test_date
    recorded_at
  end

  def ignore_date_validates
    !(new_record? || recorded_at != recorded_at_was)
  end

  # A nota é uma por aluno (índice único em complementary_exam_students). Aluno com duas matrículas enturmadas
  # na mesma data chega com duas linhas ativas e grava uma só: a do registro já salvo ou, sem ele, a primeira
  # com nota.
  def students_attributes=(attributes)
    super(one_active_row_per_student(attributes))
  end

  private

  def one_active_row_per_student(attributes)
    rows = nested_student_rows(attributes)
    discarded_rows = rows.select { |row| active_student_row?(row) }
                         .group_by { |row| row[:student_id].to_s }
                         .values
                         .flat_map { |student_rows| rows_besides_preferred(student_rows) }

    rows.reject { |row| discarded_rows.any? { |discarded| discarded.equal?(row) } }
  end

  def nested_student_rows(attributes)
    rows = attributes.is_a?(Hash) ? attributes.values : Array(attributes)

    rows.map(&:with_indifferent_access)
  end

  # equal? e não ==: duas linhas em branco do mesmo aluno são hashes iguais
  def rows_besides_preferred(student_rows)
    preferred_row = preferred_student_row(student_rows)

    student_rows.reject { |row| row.equal?(preferred_row) }
  end

  def preferred_student_row(student_rows)
    student_rows.find { |row| row[:id].present? } ||
      student_rows.find { |row| row[:score].present? } ||
      student_rows.first
  end

  def active_student_row?(row)
    ActiveRecord::Type::Boolean.new.cast(row[:active]) && !ActiveRecord::Type::Boolean.new.cast(row[:_destroy])
  end

  def at_least_one_score
    errors.add(:students, :at_least_one_score) if students.reject(&:marked_for_destruction?).reject{|s| s.score.blank? }.empty?
  end

  def self_assign_to_students
    students.each { |student| student.complementary_exam = self }
  end

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      self.validation_type = :destroy
      valid?
      !errors[:recorded_at].include?(I18n.t('errors.messages.not_allowed_to_post_in_date'))
    end
  end

  def recorded_at_year_in_settings_year
    return if complementary_exam_setting.blank?
    return if recorded_at.try(:year) == complementary_exam_setting.year

    errors.add(:recorded_at, :must_be_same_avaliation_setting_year)
  end
end
