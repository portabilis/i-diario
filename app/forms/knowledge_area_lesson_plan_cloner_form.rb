class KnowledgeAreaLessonPlanClonerForm
  include ActiveModel::Model

  attr_accessor :classroom_ids, :knowledge_area_lesson_plan_id

  validates :knowledge_area_lesson_plan_id, :classroom_ids, presence: true

  def clone!
    if valid?
      begin
        ActiveRecord::Base.transaction do
          Classroom.where(id: classroom_ids.split(",")).each do |classroom|
            new_lesson_plan = knowledge_area_lesson_plan.dup
            new_lesson_plan.lesson_plan = knowledge_area_lesson_plan.lesson_plan.dup
            new_lesson_plan.lesson_plan.unity = classroom.unity
            new_lesson_plan.knowledge_areas = knowledge_area_lesson_plan.knowledge_areas
            new_lesson_plan.lesson_plan.contents = knowledge_area_lesson_plan.lesson_plan.contents
            new_lesson_plan.lesson_plan.classroom = classroom
            new_lesson_plan.save!
          end
          return true
        end
      rescue ActiveRecord::RecordInvalid => e
        message = e.to_s
        message.slice!("A validação falhou: ")
        message.slice!("Áreas de conhecimento ")
        message = "Turma #{e.record.lesson_plan.try(:classroom)}: #{message}"
        errors.add(:classroom_ids, message)
        return false
      end
    end
  end

  def knowledge_area_lesson_plan
    @knowledge_area_lesson_plan ||= KnowledgeAreaLessonPlan.find(knowledge_area_lesson_plan_id)
  end
end
