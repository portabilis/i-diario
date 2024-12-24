class ConceptualExamValue < ActiveRecord::Base

  acts_as_copy_target

  audited associated_with: :conceptual_exam, except: :conceptual_exam_id

  belongs_to :conceptual_exam
  belongs_to :discipline

  validates :conceptual_exam, presence: true
  validates :discipline_id, presence: true

  validates :conceptual_exam_id, uniqueness: { scope: :discipline_id }

  before_destroy :valid_for_destruction?

  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_conceptual_exam_id, lambda { |conceptual_exam_id| where(conceptual_exam_id: conceptual_exam_id) }
  scope :by_not_poster, ->(poster_sent) { where("conceptual_exam_values.updated_at > ?", poster_sent) }

  def self.active(join_conceptual_exam = true)
    scoped = if join_conceptual_exam
       joins(:conceptual_exam)
    else
      all
    end

    scoped.active_query
  end

  def self.ordered
    joins(
      arel_table.join(KnowledgeArea.arel_table, Arel::Nodes::OuterJoin)
        .on(KnowledgeArea.arel_table[:id].eq(arel_table[:discipline_id]))
        .join_sources
    )
    .order(KnowledgeArea.arel_table[:description])
  end

  def mark_as_invisible
    @marked_as_invisible = true
  end

  def marked_as_invisible?
    @marked_as_invisible
  end

  private

  def self.active_query
    differentiated_exam_rules = ExamRule.arel_table.alias('differentiated_exam_rules')
    differentiated_exam_rule_students = Student.arel_table.alias('differentiated_exam_rule_students')

    joins(
      arel_table.join(TeacherDisciplineClassroom.arel_table).
        on(TeacherDisciplineClassroom.arel_table[:classroom_id].eq(ConceptualExam.arel_table[:classroom_id]).
          and(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(arel_table[:discipline_id]))).join_sources,
      arel_table.join(Classroom.arel_table).
        on(Classroom.arel_table[:id].eq(ConceptualExam.arel_table[:classroom_id])).join_sources,
      arel_table.join(ClassroomsGrade.arel_table).
        on(ClassroomsGrade.arel_table[:classroom_id].eq(ConceptualExam.arel_table[:classroom_id])).join_sources,
      arel_table.join(ExamRule.arel_table).
        on(ExamRule.arel_table[:id].eq(ClassroomsGrade.arel_table[:exam_rule_id])).join_sources,
      arel_table.join(differentiated_exam_rule_students, Arel::Nodes::OuterJoin).
        on(differentiated_exam_rule_students[:id].eq(ConceptualExam.arel_table[:student_id]).
          and(differentiated_exam_rule_students[:uses_differentiated_exam_rule].eq(true))).join_sources,
      arel_table.join(differentiated_exam_rules, Arel::Nodes::OuterJoin).
        on(differentiated_exam_rules[:id].eq(ExamRule.arel_table[:differentiated_exam_rule_id])).join_sources
    ).where(
      ExamRule.arel_table[:score_type].eq(ScoreTypes::CONCEPT).
        or(
          ExamRule.arel_table[:score_type].eq(ScoreTypes::NUMERIC_AND_CONCEPT).
          and(TeacherDisciplineClassroom.arel_table[:score_type].eq(ScoreTypes::CONCEPT))
        ).or(
          differentiated_exam_rules[:score_type].eq(ScoreTypes::CONCEPT).
          and(differentiated_exam_rule_students[:id].not_eq(nil))
        )
      ).distinct
  end

  def valid_for_destruction?
    return true unless conceptual_exam.present?
    conceptual_exam.valid_for_destruction?
  end
end
