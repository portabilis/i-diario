class ConceptualExamValue < ActiveRecord::Base

  default_scope do
    where("
      EXISTS(SELECT 1 FROM teacher_discipline_classrooms
              WHERE teacher_discipline_classrooms.discipline_id = conceptual_exam_values.discipline_id
                AND score_type IN (:score_type) limit 1)",
      score_type: [DisciplineScoreTypes::CONCEPT, nil]
    )
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
