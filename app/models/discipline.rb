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
  scope :by_score_type, lambda { |score_type|
    joins(%{
            INNER JOIN "classrooms" ON "classrooms"."id" = "teacher_discipline_classrooms"."classroom_id"
            INNER JOIN "exam_rules" ON "exam_rules"."id" = "classrooms"."exam_rule_id"
            LEFT OUTER JOIN "exam_rules" "differentiated_exam_rules" ON "differentiated_exam_rules"."id" = "exam_rules"."differentiated_exam_rule_id"
          }).
    where(%{coalesce(differentiated_exam_rules.score_type, exam_rules.score_type) = :score_type_target
            OR (
                 "exam_rules"."score_type" = :score_type_numeric_and_concept
                 AND
                 "teacher_discipline_classrooms"."score_type" = :discipline_score_type_target
               )
          }, SCORE_TYPE_FILTERS[score_type.to_sym])
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
