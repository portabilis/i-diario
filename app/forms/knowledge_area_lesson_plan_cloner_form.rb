class KnowledgeAreaLessonPlanClonerForm < ApplicationRecord
  has_no_table

  attr_accessor :knowledge_area_lesson_plan_id, :teacher, :entity_id

  validates :knowledge_area_lesson_plan_id, presence: true
  has_many :knowledge_area_lesson_plan_item_cloner_form
  accepts_nested_attributes_for :knowledge_area_lesson_plan_item_cloner_form, allow_destroy: true

  def clone!
    return unless valid?

    begin
      @classrooms = Classroom.where(id: knowledge_area_lesson_plan_item_cloner_form.map(&:classroom_id).uniq)
      copy_attachments_data = []
      ActiveRecord::Base.transaction do
        knowledge_area_lesson_plan_item_cloner_form.each_with_index do |item, index|
          @current_item_index = index
          new_lesson_plan = knowledge_area_lesson_plan.dup
          new_lesson_plan.teacher_id = teacher.id
          new_lesson_plan.lesson_plan = knowledge_area_lesson_plan.lesson_plan.dup
          new_lesson_plan.lesson_plan.teacher = teacher
          new_lesson_plan.knowledge_areas = knowledge_area_lesson_plan.knowledge_areas
          new_lesson_plan.lesson_plan.original_contents = knowledge_area_lesson_plan.lesson_plan.contents
          new_lesson_plan.lesson_plan.contents_created_at_position = {}

          new_lesson_plan.lesson_plan.original_contents.each_with_index do |content, position|
            new_lesson_plan.lesson_plan.contents_created_at_position[content.id] = position
          end

          new_lesson_plan.lesson_plan.original_objectives = knowledge_area_lesson_plan.lesson_plan.objectives
          new_lesson_plan.lesson_plan.objectives_created_at_position = {}
          new_lesson_plan.lesson_plan.original_objectives.each_with_index do |objective, position|
            new_lesson_plan.lesson_plan.objectives_created_at_position[objective.id] = position
          end

          new_lesson_plan.lesson_plan.start_at = item.start_at
          new_lesson_plan.lesson_plan.end_at = item.end_at
          new_lesson_plan.lesson_plan.classroom = @classrooms.find_by(id: item.classroom_id)

          original_attachments = {}
          knowledge_area_lesson_plan.lesson_plan.lesson_plan_attachments.each do |lesson_plan_attachment|
            original_attachments[lesson_plan_attachment.attachment.filename] = lesson_plan_attachment.id
            new_lesson_plan.lesson_plan.lesson_plan_attachments << lesson_plan_attachment.dup
          end
          new_lesson_plan.save!
          copy_attachments_data << {id: new_lesson_plan.id, original_attachments: original_attachments}
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      message = e.to_s
      message.slice!('A validação falhou: ')
      message.slice!('Áreas de conhecimento ')
      messages = message.split(',')

      messages.each do |message|
        field = set_field(message.strip)
        knowledge_area_lesson_plan_item_cloner_form[@current_item_index].errors.add(field, message + '.')
      end

      errors.add(:classroom_id, "Turma #{e.record.lesson_plan.try(:classroom)}: #{message}")

      return false
    end
    copy_attachments_data.each do |attachment|
      copy_attachments(attachment[:id], attachment[:original_attachments])
    end
    return true
  end

  def set_field(message)
    if message.start_with? I18n.t('activerecord.attributes.knowledge_area_lesson_plan.lesson_plan.start_at')
      :start_at
    elsif message.start_with? I18n.t('activerecord.attributes.knowledge_area_lesson_plan.lesson_plan.end_at')
      :end_at
    else
      :classroom_id
    end
  end

  def knowledge_area_lesson_plan
    @knowledge_area_lesson_plan ||= KnowledgeAreaLessonPlan.includes(lesson_plan: [:objectives, :contents])
                                                           .find(knowledge_area_lesson_plan_id)
  end

  def copy_attachments(new_lesson_plan_id, original_attachments)
    return if new_lesson_plan_id.blank? || original_attachments.blank?

    LessonPlanAttachmentCopierWorker.perform_async(
      entity_id,
      new_lesson_plan_id,
      KnowledgeAreaLessonPlan,
      original_attachments
    )
  end
end
