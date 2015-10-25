class KnowledgeAreaLessonPlanKnowledgeArea < ActiveRecord::Base
  belongs_to :knowledge_area_lesson_plan
  belongs_to :knowledge_area

  validates :knowledge_area_lesson_plan, presence: true
  validates :knowledge_area, presence: true
end
