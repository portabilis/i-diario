class DeleteInvalidPresenceRecordWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, student_id, classroom_id)
    Entity.find(entity_id).using_connection do
      DeleteInvalidPresenceRecordService.new(student_id, classroom_id).run!
    end
  end
end
