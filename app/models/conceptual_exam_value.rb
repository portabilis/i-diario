class ConceptualExamValue < ActiveRecord::Base

  acts_as_copy_target

  audited associated_with: :conceptual_exam, except: :conceptual_exam_id

  attr_accessor :exempted_discipline

  belongs_to :conceptual_exam
  belongs_to :discipline

  validates :conceptual_exam, presence: true
  validates :discipline_id, presence: true

  def self.active
    joins(:conceptual_exam).
      joins(active_joins).
      where(active_query)
  end

  def self.ordered
    joins(
      arel_table.join(KnowledgeArea.arel_table, Arel::Nodes::OuterJoin)
        .on(KnowledgeArea.arel_table[:id].eq(arel_table[:discipline_id]))
        .join_sources
    )
    .order(KnowledgeArea.arel_table[:description])
  end

  def self.active_joins
    <<-SQL
      INNER JOIN "teacher_discipline_classrooms" ON "teacher_discipline_classrooms"."classroom_id" = "conceptual_exams"."classroom_id"
              AND "teacher_discipline_classrooms"."discipline_id" = "conceptual_exam_values"."discipline_id"
      INNER JOIN "classrooms" ON "classrooms"."id" = "conceptual_exams"."classroom_id"
      LEFT OUTER JOIN "students" ON "students"."id" = "conceptual_exams"."student_id" AND "students"."uses_differentiated_exam_rule" = true
      INNER JOIN "exam_rules" ON "exam_rules"."id" = "classrooms"."exam_rule_id"
      LEFT OUTER JOIN "exam_rules" "differentiated_exam_rules" ON "differentiated_exam_rules"."id" = "exam_rules"."differentiated_exam_rule_id"
    SQL
  end

  def self.active_query
    <<-SQL
      "exam_rules"."score_type" = '2'
      OR ("exam_rules"."score_type" = '3' AND "teacher_discipline_classrooms"."score_type" = '1')
      OR ("differentiated_exam_rules"."score_type" = '2' AND "students"."id" IS NOT NULL)
    SQL
  end

  def mark_as_invisible
    @marked_as_invisible = true
  end

  def marked_as_invisible?
    @marked_as_invisible
  end
end
