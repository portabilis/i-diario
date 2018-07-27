class Discipline < ActiveRecord::Base

  SCORE_TYPE_FILTERS = {
    concept: {
      score_type_numeric_and_concept: '3',
      score_type_target: '2',
      discipline_score_type_target: '1'
    },
    numeric: {
      score_type_numeric_and_concept: '3',
      score_type_target: '1',
      discipline_score_type_target: '2'
    }
  }

  acts_as_copy_target

  belongs_to :knowledge_area
  has_many :teacher_discipline_classrooms, dependent: :destroy

  validates :description, :api_code, :knowledge_area_id, presence: true
  validates :api_code, uniqueness: true

  scope :by_unity_id, lambda { |unity_id| by_unity_id(unity_id) }
  scope :by_teacher_id, lambda { |teacher_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id }).uniq }

  # It works only when the query chain has join with
  # teacher_discipline_classrooms. Using scopes like by_teacher_id or
  # by_classroom for example.
  scope :by_score_type, lambda { |score_type, student_id = nil|
    scoped = joins(teacher_discipline_classrooms: { classroom: :exam_rule })
    if student_id && Student.find(student_id).try(:uses_differentiated_exam_rule)
      exam_rules = ExamRule.arel_table.alias('exam_rules_classrooms')

      differentiated_exam_rules = ExamRule.arel_table.alias('differentiated_exam_rules')
        scoped.joins(
          arel_table.join(differentiated_exam_rules, Arel::Nodes::OuterJoin).
            on(differentiated_exam_rules[:id].eq(exam_rules[:differentiated_exam_rule_id])).join_sources
        ).where(
          exam_rules[:score_type].eq(SCORE_TYPE_FILTERS[score_type.to_sym][:score_type_target]).or(
            exam_rules[:score_type].eq(SCORE_TYPE_FILTERS[score_type.to_sym][:score_type_numeric_and_concept]).
            and(TeacherDisciplineClassroom.arel_table[:score_type].eq(SCORE_TYPE_FILTERS[score_type.to_sym][:discipline_score_type_target]))
          ).or(
            differentiated_exam_rules[:score_type].eq(SCORE_TYPE_FILTERS[score_type.to_sym][:score_type_target])
          )
        ).uniq
    else
      scoped.where(
        ExamRule.arel_table[:score_type].eq(SCORE_TYPE_FILTERS[score_type.to_sym][:score_type_target]).
        or(
          ExamRule.arel_table[:score_type].eq(SCORE_TYPE_FILTERS[score_type.to_sym][:score_type_numeric_and_concept]).
          and(TeacherDisciplineClassroom.arel_table[:score_type].eq(SCORE_TYPE_FILTERS[score_type.to_sym][:discipline_score_type_target]))
        )
      ).uniq
    end
  }

  scope :by_grade, lambda { |grade| by_grade(grade) }
  scope :by_classroom, lambda { |classroom| by_classroom(classroom) }
  scope :by_teacher_and_classroom, lambda { |teacher_id, classroom_id| joins(:teacher_discipline_classrooms).where(teacher_discipline_classrooms: { teacher_id: teacher_id, classroom_id: classroom_id }).uniq }
  scope :ordered, -> { order(arel_table[:description].asc) }
  scope :order_by_sequence, -> { order(arel_table[:sequence].asc) }

  def to_s
    description
  end

  private

  def self.by_unity_id(unity_id)
    joins(:teacher_discipline_classrooms).joins(
        arel_table.join(Classroom.arel_table)
          .on(
            Classroom.arel_table[:id]
              .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
          )
          .join_sources
      )
      .where(classrooms: { unity_id: unity_id })
      .uniq
  end

  def self.by_grade(grade)
    joins(:teacher_discipline_classrooms).joins(
        arel_table.join(Classroom.arel_table)
          .on(
            Classroom.arel_table[:id]
              .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
          )
          .join_sources
      )
      .where(classrooms: { grade_id: grade })
      .uniq
  end

  def self.by_classroom(classroom)
    joins(:teacher_discipline_classrooms).where(
        teacher_discipline_classrooms: { classroom_id: classroom }
      )
      .uniq
  end
end
