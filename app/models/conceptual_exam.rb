class ConceptualExam < ActiveRecord::Base
  include Audit
  include Stepable
  include Filterable

  acts_as_copy_target

  # acts_as_paranoid

  audited
  has_associated_audits

  attr_accessor :unity_id, :teacher_id

  belongs_to :classroom
  belongs_to :student
  has_many :conceptual_exam_values, -> {
    includes(:conceptual_exam, discipline: :knowledge_area)
  }, dependent: :destroy
  belongs_to :school_calendar_step, -> { unscope(where: :active) }
  belongs_to :school_calendar_classroom_step, -> { unscope(where: :active) }

  accepts_nested_attributes_for :conceptual_exam_values, allow_destroy: true

  has_enumeration_for :status, with: ConceptualExamStatus, create_helpers: true

  scope :by_unity, lambda { |unity| joins(:classroom).where(classrooms: { unity_id: unity }) }
  scope :by_classroom, lambda { |classroom| where(classroom: classroom) }
  scope :by_discipline, lambda { |discipline| join_conceptual_exam_values.where(conceptual_exam_values: { discipline: discipline } ) }
  scope :by_student_name, lambda { |student_name| joins(:student).where('unaccent(students.name) ILIKE unaccent(?)', "%#{student_name}%") }
  scope :ordered, -> { order(recorded_at: :desc) }

  validates :student, :unity_id, presence: true
  validate :student_must_have_conceptual_exam_score_type
  validate :at_least_one_conceptual_exam_value
  validate :uniqueness_of_student
  validate :ensure_student_is_in_classroom

  before_validation :self_assign_to_conceptual_exam_values

  def self.active
    join_conceptual_exam_values.merge(ConceptualExamValue.active(false))
  end

  def self.by_teacher(teacher_id)
    active.where(
      TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id)
    ).uniq
  end

  def self.by_status(status)
    incomplete_conceptual_exams_ids = ConceptualExamValue.active.where(value: nil)
                                                         .group(:conceptual_exam_id)
                                                         .pluck(:conceptual_exam_id)

    case status
    when ConceptualExamStatus::INCOMPLETE
      where(arel_table[:id].in(incomplete_conceptual_exams_ids))
    when ConceptualExamStatus::COMPLETE
      where.not(arel_table[:id].in(incomplete_conceptual_exams_ids))
    end
  end

  def status
    discipline_ids = TeacherDisciplineClassroom.where(classroom_id: classroom_id, teacher_id: teacher_id).pluck(:discipline_id)
    values = ConceptualExamValue.where(conceptual_exam_id: id, exempted_discipline: false, discipline_id: discipline_ids)

    return ConceptualExamStatus::INCOMPLETE if values.any? { |conceptual_exam_value| conceptual_exam_value.value.blank? }

    ConceptualExamStatus::COMPLETE
  end

  private

  def student_must_have_conceptual_exam_score_type
    return if student.blank? || classroom.blank?

    permited_score_types = [ScoreTypes::CONCEPT, ScoreTypes::NUMERIC_AND_CONCEPT]
    exam_rule = classroom.exam_rule
    exam_rule = (exam_rule.differentiated_exam_rule || exam_rule) if student.uses_differentiated_exam_rule

    unless permited_score_types.include?(exam_rule.score_type)
      errors.add(:student, :classroom_must_have_conceptual_exam_score_type)
    end
  end

  def at_least_one_conceptual_exam_value
    if conceptual_exam_values.reject(&:marked_for_destruction?).reject(&:marked_as_invisible?).empty?
      errors.add(:conceptual_exam_values, :at_least_one_conceptual_exam_value)
    end
  end

  def self_assign_to_conceptual_exam_values
    conceptual_exam_values.each { |conceptual_exam_value| conceptual_exam_value.conceptual_exam = self }
  end

  def self.join_conceptual_exam_values
    joins(
      arel_table.join(
        ConceptualExamValue.arel_table
      ).on(
        ConceptualExamValue.arel_table[:conceptual_exam_id].
          eq(arel_table[:id])
      ).join_sources
    )
  end

  def uniqueness_of_student
    return if step.blank? || student_id.blank?

    discipline_ids = conceptual_exam_values.collect{ |value| value.discipline_id }
    conceptual_exam = ConceptualExam.joins(:conceptual_exam_values)
                                    .by_recorded_at_between(step.start_at, step.end_at)
                                    .where(
                                      student_id: student_id,
                                      classroom_id: classroom_id,
                                      conceptual_exam_values: { discipline_id: discipline_ids }
                                    )

    conceptual_exam = conceptual_exam.where.not(id: id) if persisted?

    errors.add(:student, :taken) if conceptual_exam.exists?
  end

  def ensure_student_is_in_classroom
    return if recorded_at.blank? || student_id.blank? || classroom_id.blank?

    unless StudentEnrollment.by_student(student_id).by_classroom(classroom_id).by_date(recorded_at).exists?
      errors.add(:base, :student_is_not_in_classroom)
    end
  end
end
