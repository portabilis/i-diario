class KnowledgeAreaLessonPlanClonerForm < ActiveRecord::Base
  has_no_table

  attr_accessor :knowledge_area_lesson_plan_id

  validates :knowledge_area_lesson_plan_id,  presence: true
  has_many :knowledge_area_lesson_plan_item_cloner_form
  accepts_nested_attributes_for :knowledge_area_lesson_plan_item_cloner_form, :allow_destroy => true

  def clone!
    if valid?
      begin
        ActiveRecord::Base.transaction do
          @classrooms = Classroom.where(id: knowledge_area_lesson_plan_item_cloner_form.map(&:classroom_id).uniq)
          knowledge_area_lesson_plan_item_cloner_form.each_with_index do |item, index|
            @current_item_index = index
            new_lesson_plan = knowledge_area_lesson_plan.dup
            new_lesson_plan.lesson_plan = knowledge_area_lesson_plan.lesson_plan.dup
            new_lesson_plan.knowledge_areas = knowledge_area_lesson_plan.knowledge_areas
            new_lesson_plan.lesson_plan.contents = knowledge_area_lesson_plan.lesson_plan.contents
            new_lesson_plan.lesson_plan.start_at = item.start_at
            new_lesson_plan.lesson_plan.end_at = item.end_at
            new_lesson_plan.lesson_plan.classroom = @classrooms.find_by_id(item.classroom_id)
            knowledge_area_lesson_plan.lesson_plan.lesson_plan_attachments.each do |lesson_plan_attachment|
              new_lesson_plan.lesson_plan.lesson_plan_attachments << LessonPlanAttachment.new(attachment: lesson_plan_attachment.attachment)
            end
            new_lesson_plan.save!
          end
          return true
        end
      rescue ActiveRecord::RecordInvalid => e
        message = e.to_s
        message.slice!("A validação falhou: ")
        message.slice!("Áreas de conhecimento ")
        errors.add(:classroom_id, "Turma #{e.record.lesson_plan.try(:classroom)}: #{message}")
        knowledge_area_lesson_plan_item_cloner_form[@current_item_index].errors.add(:classroom_id, message)
        return false
      end
    end
  end

  def knowledge_area_lesson_plan
    @knowledge_area_lesson_plan ||= KnowledgeAreaLessonPlan.find(knowledge_area_lesson_plan_id)
  end
end
