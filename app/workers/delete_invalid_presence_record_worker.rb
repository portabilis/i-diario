class DeleteInvalidPresenceRecordWorker
  include Sidekiq::Worker
  include EntityWorker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform_in_entity(student_id, classroom_id)
    DeleteInvalidPresenceRecordService.new(student_id, classroom_id).run!
  end
end
