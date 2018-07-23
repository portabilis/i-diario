class ConceptualExamValue < ActiveRecord::Base

  default_scope do
    query = <<-SQL
      EXISTS(SELECT 1
            FROM "conceptual_exams"
            INNER JOIN "teacher_discipline_classrooms" ON "teacher_discipline_classrooms"."classroom_id" = "conceptual_exams"."classroom_id"
                   AND "teacher_discipline_classrooms"."discipline_id" = "conceptual_exam_values"."discipline_id"
            WHERE ("teacher_discipline_classrooms"."score_type" = ?
               OR  "teacher_discipline_classrooms"."score_type" IS NULL)
              AND "conceptual_exams"."id" = "conceptual_exam_values"."conceptual_exam_id"
            LIMIT 1)
    SQL

    where(query, DisciplineScoreTypes::CONCEPT)
  end

  acts_as_copy_target

  audited associated_with: :conceptual_exam, except: :conceptual_exam_id

  attr_accessor :exempted_discipline

  belongs_to :conceptual_exam
  belongs_to :discipline

  validates :conceptual_exam, presence: true
  validates :discipline_id, presence: true

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
end
