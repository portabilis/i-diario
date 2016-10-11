class ConceptualExam < ActiveRecord::Base
  include Audit
  include Filterable

  acts_as_copy_target

  audited
  has_associated_audits

  attr_accessor :unity_id

  belongs_to :classroom
  belongs_to :school_calendar_step
  belongs_to :student
  has_many :conceptual_exam_values, -> { includes(:conceptual_exam, discipline: :knowledge_area) },
    dependent: :destroy

  accepts_nested_attributes_for :conceptual_exam_values, allow_destroy: true

  has_enumeration_for :status, with: ConceptualExamStatus,  create_helpers: true

  scope :by_unity, lambda { |unity| joins(:classroom).where(classrooms: { unity_id: unity }) }
  scope :by_classroom, lambda { |classroom| where(classroom: classroom) }
  scope :by_discipline, lambda { |discipline| joins(:conceptual_exam_values).where(conceptual_exam_values: { discipline: discipline } ) }
  scope :by_student_name, lambda { |student_name| joins(:student).where(Student.arel_table[:name].matches("%#{student_name}%")) }
  scope :by_school_calendar_step, lambda { |school_calendar_step| where(school_calendar_step: school_calendar_step) }
  scope :ordered, -> { order(recorded_at: :desc)  }

  validates :classroom,  presence: true
  validates :school_calendar_step, presence: true
  validates :student, presence: true
  validates :recorded_at, presence: true,
    not_in_future: true,
    school_term_day: { school_term: lambda(&:school_calendar_step) }
  validates :unity_id, presence: true

  validate :classroom_must_have_conceptual_exam_score_type
  validate :at_least_one_conceptual_exam_value
  validate :uniqueness_of_student

  before_validation :self_assign_to_conceptual_exam_values

  def self.by_teacher(teacher)
    joins(
        arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
          .on(TeacherDisciplineClassroom.arel_table[:classroom_id].eq(arel_table[:classroom_id]))
          .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher))
      .uniq
  end

  def self.by_status(status)
    incomplete_conceptual_exams_ids = ConceptualExamValue.where(value: nil)
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
    values = ConceptualExamValue.where(conceptual_exam_id: id)
    if values.any? { |conceptual_exam_value| conceptual_exam_value.value.blank? }
      ConceptualExamStatus::INCOMPLETE
    else
      ConceptualExamStatus::COMPLETE
    end
  end

  private

  def classroom_must_have_conceptual_exam_score_type
    return if classroom.blank?

    if classroom.exam_rule.score_type != ScoreTypes::CONCEPT
      errors.add(:classroom, :classroom_must_have_conceptual_exam_score_type)
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

  def uniqueness_of_student
    discipline_ids = conceptual_exam_values.collect{ |value| value.discipline_id }
    conceptual_exam = ConceptualExam.joins(:conceptual_exam_values).where(student_id: student_id, classroom_id: classroom_id, school_calendar_step_id: school_calendar_step_id, conceptual_exam_values: { discipline_id: discipline_ids })
    conceptual_exam = conceptual_exam.where.not(id: id) if persisted?

    errors.add(:student, :taken) if conceptual_exam.any?
  end
end
