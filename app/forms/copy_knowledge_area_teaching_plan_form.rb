class CopyKnowledgeAreaTeachingPlanForm
  include ActiveModel::Model

  attr_accessor :unities_ids,
                :grades_ids,
                :year,
                :knowledge_area_teaching_plan,
                :teaching_plan

  validates :unities_ids,
            :grades_ids,
            :year,
            :knowledge_area_teaching_plan,
            :teaching_plan,
            presence: true
end
