class KnowledgeAreaLessonPlanItemClonerForm < ApplicationRecord
  has_no_table

  attr_accessor :uuid, :knowledge_area_lesson_plan_cloner_form_id, :classroom_id, :start_at, :end_at
  belongs_to :knowledge_area_lesson_plan_cloner_form

  validates :classroom_id, :start_at, :end_at, presence: true
end
