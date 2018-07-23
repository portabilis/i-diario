class ConceptualExamValue < ActiveRecord::Base

  default_scope do
    # Retorna apenas os valores relacionados a:
    # - Regra da turma como nota conceitual;
    # - Regra da turma como nota conceitual ou numérica porém disciplina marcada
    #   como conceitual;
    query = <<-SQL
      EXISTS(SELECT 1
          FROM "conceptual_exams"
          INNER JOIN "teacher_discipline_classrooms" ON "teacher_discipline_classrooms"."classroom_id" = "conceptual_exams"."classroom_id"
                 AND "teacher_discipline_classrooms"."discipline_id" = "conceptual_exam_values"."discipline_id"
          INNER JOIN "classrooms" ON "classrooms"."id" = "conceptual_exams"."classroom_id"
          INNER JOIN "exam_rules" ON "exam_rules"."id" = "classrooms"."exam_rule_id"
          LEFT OUTER JOIN "exam_rules" "differentiated_exam_rules" ON "differentiated_exam_rules"."id" = "exam_rules"."differentiated_exam_rule_id"
          WHERE (coalesce(differentiated_exam_rules.score_type, exam_rules.score_type) = :score_type_numeric_and_concept
                 OR (coalesce(differentiated_exam_rules.score_type, exam_rules.score_type) = :score_type_target
                     AND "teacher_discipline_classrooms"."score_type" = :discipline_score_type_target))
            AND "conceptual_exams"."id" = "conceptual_exam_values"."conceptual_exam_id"
          LIMIT 1)
    SQL

    where(query, Discipline::SCORE_TYPE_FILTERS[:concept])
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
