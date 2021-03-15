class LessonPlanAttachmentCopierWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, new_lesson_plan_id, klass, original_attachments)
    Entity.find(entity_id).using_connection do
      LessonPlanAttachmentCopier.copy!(new_lesson_plan_id, klass, original_attachments)
    end
  end
end
