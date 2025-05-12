class ConceptualExam < ActiveRecord::Base
  include Audit
  include Stepable
  include Discardable
  include ColumnsLockable
  include TeacherRelationable

  not_updatable only: :classroom_id
  teacher_relation_columns only: :classroom

  acts_as_copy_target

  audited
  has_associated_audits

  attr_accessor :unity_id

  before_destroy :valid_for_destruction?

  belongs_to :classroom
  belongs_to :student
  has_many :conceptual_exam_values, lambda {
    includes(:conceptual_exam, discipline: :knowledge_area)
  }, inverse_of: :conceptual_exam, dependent: :destroy

  accepts_nested_attributes_for :conceptual_exam_values, allow_destroy: true

  has_enumeration_for :status, with: ConceptualExamStatus, create_helpers: true

  default_scope -> { kept }

  scope :by_unity, ->(unity) { joins(:classroom).where(classrooms: { unity_id: unity }) }
  scope :by_classroom, ->(classroom) { where(classroom: classroom) }
  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_student_id, ->(student_id) { where(student_id: student_id) }
  scope :by_step_number, ->(step_number) { where(step_number: step_number) }
  scope :by_discipline, lambda { |discipline|
    join_conceptual_exam_values.where(conceptual_exam_values: { discipline: discipline })
  }
  scope :by_student_name, lambda { |student_name|
    joins(
      arel_table.join(Student.arel_table).on(
        Student.arel_table[:id].eq(ConceptualExam.arel_table[:student_id])
      ).join_sources
    ).where(
      "(unaccent(students.name) ILIKE unaccent(:student_name) or
        unaccent(students.social_name) ILIKE unaccent(:student_name))",
      student_name: "%#{student_name}%"
    )
  }
  scope :ordered, -> { order(recorded_at: :desc) }
  scope :ordered_by_date_and_student, -> {
    joins(
      arel_table.join(Student.arel_table).on(
        Student.arel_table[:id].eq(ConceptualExam.arel_table[:student_id])
      ).join_sources
    ).order(recorded_at: :desc)
    .order(Student.arel_table[:name])
    .select(Student.arel_table[:name])
  }

  validates :student, :unity_id, presence: true
  validate :student_must_have_conceptual_exam_score_type
  validate :at_least_one_conceptual_exam_value
  validate :uniqueness_of_student
  validate :ensure_student_is_in_classroom

  def self.active
    join_conceptual_exam_values.merge(ConceptualExamValue.active(false))
  end

  def self.by_teacher(teacher_id)
    active.where(
      TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id)
    ).distinct
  end

  def self.by_status(classroom_id, teacher_id, status)
    discipline_ids = TeacherDisciplineClassroom.by_classroom(classroom_id)
                                               .by_teacher_id(teacher_id)
                                               .pluck(:discipline_id)

    exempted_discipline_ids = SpecificStep.where(classroom_id: classroom_id)
                                          .where.not(used_steps: '')
                                          .pluck(:discipline_id)

    incomplete_conceptual_exams_ids = ConceptualExamValue.joins(:conceptual_exam).active.where(value: nil)
                                                         .where(conceptual_exams: { classroom_id: classroom_id })
                                                         .where.not(discipline_id: exempted_discipline_ids)
                                                         .by_discipline_id(discipline_ids)
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
    discipline_ids = TeacherDisciplineClassroom.where(classroom_id: classroom_id, teacher_id: teacher_id)
                                               .pluck(:discipline_id)

    exempted_discipline_ids = ExemptedDisciplinesInStep.discipline_ids(
      classroom.id,
      step_number
    )

    values = ConceptualExamValue.where(
      conceptual_exam_id: id,
      exempted_discipline: false,
      discipline_id: discipline_ids
    ).where.not(discipline_id: exempted_discipline_ids)

    return ConceptualExamStatus::INCOMPLETE if values.blank?

    return ConceptualExamStatus::INCOMPLETE if values.any? { |conceptual_exam_value|
      conceptual_exam_value.value.blank?
    }

    ConceptualExamStatus::COMPLETE
  end

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      self.validation_type = :destroy
      valid?
      !errors[:recorded_at].include?(I18n.t('errors.messages.not_allowed_to_post_in_date'))
    end
  end

  def merge_conceptual_exam_values
    grouped_conceptual_exam_values = conceptual_exam_values.group_by { |e|
      [e.conceptual_exam_id, e.discipline_id]
    }

    self.conceptual_exam_values = grouped_conceptual_exam_values.map do |_key, conceptual_exam_values|
      next conceptual_exam_values.first if conceptual_exam_values.size == 1

      persisted = conceptual_exam_values.find(&:persisted?)
      new_record = conceptual_exam_values.find(&:new_record?)

      persisted.value = new_record.value if new_record.present?

      persisted
    end
  end

  def ignore_date_validates
    !(new_record? || recorded_at != recorded_at_was)
  end

  private

  def student_must_have_conceptual_exam_score_type
    return if student.blank? || classroom.blank? || validation_type.eql?(:destroy)

    permited_score_types = [ScoreTypes::CONCEPT, ScoreTypes::NUMERIC_AND_CONCEPT]
    classroom_grade = ClassroomsGrade.by_student_id(student.id).by_classroom_id(classroom.id)&.first

    return if classroom_grade.blank?

    exam_rule = classroom_grade&.exam_rule
    exam_rule = (exam_rule.differentiated_exam_rule || exam_rule) if student.uses_differentiated_exam_rule

    if student.uses_differentiated_exam_rule
      exam_rule = exam_rule.differentiated_exam_rule || exam_rule
    end

    return if exam_rule.blank? || permited_score_types.include?(exam_rule.score_type)

    errors.add(:student, :classroom_must_have_conceptual_exam_score_type)
  end

  def at_least_one_conceptual_exam_value
    return unless conceptual_exam_values.reject(&:marked_for_destruction?).reject(&:marked_as_invisible?).empty?

    errors.add(:conceptual_exam_values, :at_least_one_conceptual_exam_value)
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
    return if step.blank? || student_id.blank? || validation_type == :destroy

    discipline_ids = conceptual_exam_values.collect(&:discipline_id)
    conceptual_exam = ConceptualExam.joins(:conceptual_exam_values)
                                    .by_step_number(step.step_number)
                                    .where(
                                      student_id: student_id,
                                      classroom_id: classroom_id,
                                      conceptual_exam_values: { discipline_id: discipline_ids }
                                    )

    conceptual_exam = conceptual_exam.where.not(id: id) if persisted?

    errors.add(:student, :taken) if conceptual_exam.exists?
  end

  def ensure_student_is_in_classroom
    return if recorded_at.blank? || student_id.blank? || classroom_id.blank? || validation_type == :destroy
    return if StudentEnrollment.by_student(student_id).by_classroom(classroom_id).by_date(recorded_at).exists?

    errors.add(:base, :student_is_not_in_classroom)
  end
end
