class KnowledgeAreaTeachingPlanKnowledgeArea < ApplicationRecord
  audited

  belongs_to :knowledge_area_teaching_plan
  belongs_to :knowledge_area

  validates :knowledge_area_teaching_plan, presence: true
  validates :knowledge_area, presence: true
end
