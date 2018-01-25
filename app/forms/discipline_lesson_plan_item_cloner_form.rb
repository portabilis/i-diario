class DisciplineLessonPlanItemClonerForm < ActiveRecord::Base
  has_no_table

  attr_accessor :discipline_lesson_plan_cloner_form_id, :classroom_id, :start_at, :end_at

  validates :classroom_id, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
end
